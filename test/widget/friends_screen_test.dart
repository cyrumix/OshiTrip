import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/social/application/social_providers.dart';
import 'package:oshi_trip/features/social/domain/friendship.dart';
import 'package:oshi_trip/features/social/domain/profile.dart';
import 'package:oshi_trip/features/social/presentation/friends_screen.dart';

import '../helpers/pump_screen.dart';

class _FakeFriendRepo implements FriendRepository {
  _FakeFriendRepo(this.friendships);
  List<Friendship> friendships;
  final List<({String id, bool accept})> responded = [];
  final List<String> removed = [];
  final List<String> byCodeRequests = [];

  @override
  Future<Result<List<Friendship>>> fetchFriendships() async => Ok(friendships);

  @override
  Future<Result<FriendshipStatus>> sendRequest(String receiverId) async =>
      const Ok(FriendshipStatus.pending);

  @override
  Future<Result<FriendshipStatus>> sendRequestByCode(String friendCode) async {
    byCodeRequests.add(friendCode);
    return const Ok(FriendshipStatus.pending);
  }

  @override
  Future<Result<void>> respond(
    String friendshipId, {
    required bool accept,
  }) async {
    responded.add((id: friendshipId, accept: accept));
    return const Ok(null);
  }

  @override
  Future<Result<void>> removeFriend(String otherUserId) async {
    removed.add(otherUserId);
    return const Ok(null);
  }
}

class _FakeProfileRepo implements ProfileRepository {
  _FakeProfileRepo(this.byId);
  final Map<String, String> byId; // id -> displayName

  Profile _p(String id, String name, {String code = ''}) => Profile(
        userId: id,
        displayName: name,
        friendCode: code,
        createdAt: DateTime.utc(2026, 7, 11),
        updatedAt: DateTime.utc(2026, 7, 11),
      );

  @override
  Future<Result<Profile?>> fetchMyProfile() async =>
      Ok(_p('me', 'わたし', code: 'OSHI-7K3P-Q9A2'));

  @override
  Future<Result<Profile>> upsertMyProfile({
    required String displayName,
    String? bio,
    String? favoriteName,
    required bool acceptsFriendRequests,
    required bool searchable,
  }) async =>
      Ok(_p('me', displayName));

  @override
  Future<Result<Profile?>> fetchProfile(String userId) async =>
      Ok(byId.containsKey(userId) ? _p(userId, byId[userId]!) : null);

  @override
  Future<Result<Map<String, Profile>>> fetchProfiles(
    List<String> userIds,
  ) async =>
      Ok({
        for (final id in userIds)
          if (byId.containsKey(id)) id: _p(id, byId[id]!),
      });
}

Friendship _f(
  String id,
  String requester,
  String receiver,
  FriendshipStatus s,
) =>
    Friendship(
      id: id,
      requesterId: requester,
      receiverId: receiver,
      status: s,
      createdAt: DateTime.utc(2026, 7, 11),
      updatedAt: DateTime.utc(2026, 7, 11),
    );

void main() {
  final clock = FixedClock(DateTime(2026, 7, 11, 12));

  Future<_FakeFriendRepo> pump(
    WidgetTester tester,
    List<Friendship> friendships,
    Map<String, String> profiles,
  ) async {
    final friendRepo = _FakeFriendRepo(friendships);
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const FriendsScreen(),
      extraOverrides: [
        currentUserIdProvider.overrideWithValue('me'),
        friendRepositoryProvider.overrideWithValue(friendRepo),
        profileRepositoryProvider.overrideWithValue(_FakeProfileRepo(profiles)),
      ],
    );
    return friendRepo;
  }

  testWidgets('フレンドタブに承認済みの相手が表示される', (tester) async {
    await pump(
      tester,
      [_f('f1', 'me', 'u2', FriendshipStatus.accepted)],
      {'u2': 'ともだち'},
    );
    expect(find.text('ともだち'), findsOneWidget);
  });

  testWidgets('受信タブで承認するとrespond(accept:true)が呼ばれる', (tester) async {
    final repo = await pump(
      tester,
      [_f('f2', 'u3', 'me', FriendshipStatus.pending)],
      {'u3': 'しんせいしゃ'},
    );

    // 受信タブへ切り替え（受信件数つきラベル）。
    await tester.tap(find.textContaining('受信'));
    await tester.pumpAndSettle();

    expect(find.text('しんせいしゃ'), findsOneWidget);
    await tester.tap(find.byTooltip('承認'));
    await tester.pumpAndSettle();

    expect(repo.responded, isNotEmpty);
    expect(repo.responded.first.id, 'f2');
    expect(repo.responded.first.accept, isTrue);
  });

  testWidgets('申請中タブに送信中の相手が表示される', (tester) async {
    await pump(
      tester,
      [_f('f3', 'me', 'u4', FriendshipStatus.pending)],
      {'u4': 'そうしんちゅう'},
    );

    await tester.tap(find.text('申請中'));
    await tester.pumpAndSettle();

    expect(find.text('そうしんちゅう'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '取消'), findsOneWidget);
  });

  testWidgets('フレンドがいなければ空状態を表示する', (tester) async {
    await pump(tester, const [], const {});
    expect(find.text('フレンドがまだいません'), findsOneWidget);
  });

  testWidgets('自分のフレンドコードが表示されコピーできる', (tester) async {
    // Clipboard.setData がテスト環境で解決するようにモックする。
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await pump(tester, const [], const {});

    expect(find.byKey(const Key('my_friend_code')), findsOneWidget);
    expect(find.text('OSHI-7K3P-Q9A2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('copy_friend_code')));
    await tester.pump(); // Clipboard await
    await tester.pump(const Duration(milliseconds: 300)); // SnackBar 表示
    expect(copied, contains('OSHI-7K3P-Q9A2'));
    expect(find.text('フレンドコードをコピーしました'), findsOneWidget);
  });

  testWidgets('フレンドコードで追加すると sendRequestByCode が呼ばれる', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await pump(tester, const [], const {});

    await tester.tap(find.byKey(const Key('add_by_friend_code')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('friend_code_input')),
      'OSHI-AAAA-BBBB',
    );
    await tester.tap(find.byKey(const Key('friend_code_submit')));
    await tester.pumpAndSettle(); // dialog close + RPC + SnackBar

    // 入力したコードで送信 RPC が呼ばれる（＝コード完全一致で相手を特定する経路）。
    expect(repo.byCodeRequests, contains('OSHI-AAAA-BBBB'));
    expect(find.text('フレンド申請を送りました'), findsOneWidget);
  });
}
