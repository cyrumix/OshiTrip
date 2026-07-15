import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/sharing/domain/share.dart';
import 'package:oshi_trip/features/social/application/member_providers.dart';
import 'package:oshi_trip/features/social/application/social_providers.dart';
import 'package:oshi_trip/features/social/domain/friendship.dart';
import 'package:oshi_trip/features/social/domain/profile.dart';
import 'package:oshi_trip/features/social/presentation/genba_members_screen.dart';

import '../helpers/pump_screen.dart';

class _FakeShareRepo implements ShareRepository {
  final List<GenbaShare> upserted = [];
  final List<String> removed = [];

  @override
  Stream<List<GenbaShare>> watchShares(String genbaId) =>
      Stream.value(const []);

  @override
  Future<Result<void>> upsertShare(GenbaShare share) async {
    upserted.add(share);
    return const Ok(null);
  }

  @override
  Future<Result<void>> removeShare(String shareId) async {
    removed.add(shareId);
    return const Ok(null);
  }

  @override
  Future<Result<void>> refreshFromRemote({bool Function()? isStale}) async =>
      const Ok(null);

  @override
  Future<Result<void>> adoptServerEntity(String t, String id) async =>
      const Ok(null);
}

class _FakeFriendRepo implements FriendRepository {
  final List<String> requested = [];

  @override
  Future<Result<List<Friendship>>> fetchFriendships() async => const Ok([]);

  @override
  Future<Result<FriendshipStatus>> sendRequest(String receiverId) async {
    requested.add(receiverId);
    return const Ok(FriendshipStatus.pending);
  }

  @override
  Future<Result<FriendshipStatus>> sendRequestByCode(String friendCode) async =>
      const Ok(FriendshipStatus.pending);

  @override
  Future<Result<void>> respond(String id, {required bool accept}) async =>
      const Ok(null);

  @override
  Future<Result<void>> removeFriend(String otherUserId) async => const Ok(null);
}

Profile _p(String id, String name) => Profile(
      userId: id,
      displayName: name,
      createdAt: DateTime.utc(2026, 7, 11),
      updatedAt: DateTime.utc(2026, 7, 11),
    );

GenbaShare _share(String grantee, ShareRole role) => GenbaShare(
      id: 'share-$grantee',
      ownerId: 'owner',
      genbaId: 'g1',
      granteeId: grantee,
      role: role,
      createdAt: DateTime.utc(2026, 7, 11),
      updatedAt: DateTime.utc(2026, 7, 11),
    );

void main() {
  final clock = FixedClock(DateTime(2026, 7, 11, 12));

  Future<({_FakeShareRepo share, _FakeFriendRepo friend})> pump(
    WidgetTester tester,
    MembersView view,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final shareRepo = _FakeShareRepo();
    final friendRepo = _FakeFriendRepo();
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const GenbaMembersScreen(genbaId: 'g1'),
      extraOverrides: [
        currentUserIdProvider.overrideWithValue('owner'),
        genbaMembersProvider.overrideWith((ref, id) async => view),
        genbaSharesRepositoryProvider.overrideWithValue(shareRepo),
        friendRepositoryProvider.overrideWithValue(friendRepo),
      ],
    );
    return (share: shareRepo, friend: friendRepo);
  }

  MembersView ownerView({
    List<MemberEntry> members = const [],
    List<AddableFriend> addable = const [],
  }) =>
      MembersView(
        genbaId: 'g1',
        amOwner: true,
        selfRole: ShareRole.owner,
        ownerProfile: _p('owner', 'オーナーさん'),
        members: members,
        addableFriends: addable,
      );

  testWidgets('オーナーとメンバーが権限バッジ付きで表示される', (tester) async {
    await pump(
      tester,
      ownerView(
        members: [
          MemberEntry(
            share: _share('u2', ShareRole.viewer),
            profile: _p('u2', 'メンバーA'),
          ),
        ],
      ),
    );
    expect(find.text('オーナーさん（あなた）'), findsOneWidget);
    expect(find.text('メンバーA'), findsOneWidget);
    expect(find.text('閲覧のみ'), findsWidgets);
  });

  testWidgets('メンバーへフレンド申請するとsendRequestが呼ばれる', (tester) async {
    final repos = await pump(
      tester,
      ownerView(
        members: [
          MemberEntry(
            share: _share('u2', ShareRole.viewer),
            profile: _p('u2', 'メンバーA'),
          ),
        ],
      ),
    );
    await tester.tap(find.widgetWithText(TextButton, 'フレンド申請'));
    await tester.pumpAndSettle();
    expect(repos.friend.requested, contains('u2'));
  });

  testWidgets('メンバー削除でremoveShareが呼ばれる', (tester) async {
    final repos = await pump(
      tester,
      ownerView(
        members: [
          MemberEntry(
            share: _share('u2', ShareRole.viewer),
            profile: _p('u2', 'メンバーA'),
          ),
        ],
      ),
    );
    await tester.tap(find.byTooltip('メンバーを削除'));
    await tester.pumpAndSettle();
    expect(repos.share.removed, contains('share-u2'));
  });

  testWidgets('フレンドから編集権限で追加するとupsertShareが呼ばれる', (tester) async {
    final repos = await pump(
      tester,
      ownerView(
        addable: [AddableFriend(userId: 'u3', profile: _p('u3', 'ついか候補'))],
      ),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'フレンドから追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '編集で追加'));
    await tester.pumpAndSettle();

    expect(repos.share.upserted, hasLength(1));
    expect(repos.share.upserted.first.granteeId, 'u3');
    expect(repos.share.upserted.first.role, ShareRole.editor);
  });

  testWidgets('権限が無い場合は表示できない案内を出す', (tester) async {
    await pump(
      tester,
      const MembersView(genbaId: 'g1', amOwner: false),
    );
    expect(find.text('この現場のメンバーは表示できません'), findsOneWidget);
  });

  testWidgets('非オーナーの共有メンバーはメンバー一覧と自分の権限を閲覧できる（管理導線なし, §4）', (tester) async {
    await pump(
      tester,
      MembersView(
        genbaId: 'g1',
        amOwner: false,
        isMember: true,
        selfRole: ShareRole.viewer,
        ownerProfile: _p('owner', 'オーナーさん'),
        members: [
          MemberEntry(
            share: _share('u2', ShareRole.editor),
            profile: _p('u2', 'メンバーB'),
          ),
        ],
      ),
    );

    expect(find.text('あなたの権限'), findsOneWidget);
    expect(find.text('オーナーさん'), findsOneWidget);
    expect(find.text('メンバーB'), findsOneWidget);
    // 管理導線（追加/削除/権限変更/招待）は出さない。
    expect(find.text('フレンドから追加'), findsNothing);
    expect(find.text('招待URLを作成'), findsNothing);
    expect(find.byTooltip('メンバーを削除'), findsNothing);
    expect(find.byTooltip('権限を変更'), findsNothing);
  });
}
