import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:oshi_trip/app/theme/app_theme.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/sharing/domain/genba_invite.dart';
import 'package:oshi_trip/features/sharing/domain/share.dart';
import 'package:oshi_trip/features/social/application/member_providers.dart';
import 'package:oshi_trip/features/social/application/social_providers.dart';
import 'package:oshi_trip/features/social/presentation/genba_members_screen.dart';
import 'package:oshi_trip/features/social/presentation/invite_join_screen.dart';
import 'package:oshi_trip/features/social/presentation/invite_paste_screen.dart';

import '../helpers/pump_screen.dart';

class _FakeInviteRepo implements GenbaInviteRepository {
  _FakeInviteRepo({this.invites = const [], this.preview});
  List<GenbaInvite> invites;
  final InvitePreview? preview;

  final List<({String genbaId, ShareRole role})> created = [];
  final List<String> revoked = [];
  final List<String> joined = [];

  @override
  Future<Result<List<GenbaInvite>>> fetchInvites(String genbaId) async =>
      Ok(invites);

  @override
  Future<Result<GenbaInvite>> createInvite(
    String genbaId, {
    ShareRole role = ShareRole.viewer,
    DateTime? expiresAt,
    int? maxUses,
  }) async {
    created.add((genbaId: genbaId, role: role));
    return Ok(_invite('new', role));
  }

  @override
  Future<Result<void>> revokeInvite(String inviteId) async {
    revoked.add(inviteId);
    return const Ok(null);
  }

  @override
  Future<Result<InvitePreview>> previewByToken(String token) async =>
      preview == null ? const Err(UnavailableFailure()) : Ok(preview!);

  @override
  Future<Result<InviteJoinStatus>> joinByToken(String token) async {
    joined.add(token);
    return const Ok(InviteJoinStatus.joined);
  }
}

GenbaInvite _invite(String id, ShareRole role) => GenbaInvite(
      id: id,
      genbaId: 'g1',
      ownerId: 'owner',
      token: 'tok_$id',
      defaultRole: role,
      createdAt: DateTime.utc(2026, 7, 11),
      updatedAt: DateTime.utc(2026, 7, 11),
    );

void main() {
  final clock = FixedClock(DateTime(2026, 7, 11, 12));

  group('メンバー画面の招待URLセクション', () {
    Future<_FakeInviteRepo> pumpMembers(
      WidgetTester tester,
      _FakeInviteRepo repo,
    ) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = await signedInTestDb();
      addTearDown(db.close);
      await pumpScreen(
        tester,
        db: db,
        clock: clock,
        child: const GenbaMembersScreen(genbaId: 'g1'),
        extraOverrides: [
          currentUserIdProvider.overrideWithValue('owner'),
          genbaMembersProvider.overrideWith(
            (ref, id) async => const MembersView(
              genbaId: 'g1',
              amOwner: true,
              selfRole: ShareRole.owner,
            ),
          ),
          genbaInviteRepositoryProvider.overrideWithValue(repo),
        ],
      );
      return repo;
    }

    testWidgets('招待URLを作成すると createInvite が呼ばれる', (tester) async {
      final repo = await pumpMembers(tester, _FakeInviteRepo());

      await tester.tap(find.widgetWithText(FilledButton, '招待URLを作成'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('閲覧のみ'));
      await tester.pumpAndSettle();

      expect(repo.created, hasLength(1));
      expect(repo.created.first.genbaId, 'g1');
      expect(repo.created.first.role, ShareRole.viewer);
    });

    testWidgets('既存の招待URLを無効化すると revokeInvite が呼ばれる', (tester) async {
      final repo = await pumpMembers(
        tester,
        _FakeInviteRepo(invites: [_invite('i1', ShareRole.viewer)]),
      );

      await tester.tap(find.byTooltip('招待URLを無効化'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '無効化'));
      await tester.pumpAndSettle();

      expect(repo.revoked, contains('i1'));
    });
  });

  group('招待参加確認画面', () {
    Future<_FakeInviteRepo> pumpJoin(
      WidgetTester tester,
      InvitePreview? preview,
    ) async {
      final repo = _FakeInviteRepo(preview: preview);
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(clock),
          currentUserIdProvider.overrideWithValue('me'),
          genbaInviteRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: '/invite/tok1',
        routes: [
          GoRoute(
            path: '/invite/:token',
            builder: (c, s) =>
                InviteJoinScreen(token: s.pathParameters['token']!),
          ),
          GoRoute(
            path: '/genba/:id',
            builder: (c, s) => const Scaffold(body: Text('GENBA-DETAIL')),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light().copyWith(
              splashFactory: InkRipple.splashFactory,
            ),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('有効な招待は現場情報を表示し、参加すると join→現場詳細へ', (tester) async {
      final repo = await pumpJoin(
        tester,
        InvitePreview(
          valid: true,
          genbaId: 'g9',
          artistName: 'ARASHI',
          title: 'TokyoDome',
          eventDate: DateTime.utc(2026, 8, 1),
          ownerDisplayName: 'オーナーさん',
        ),
      );

      expect(find.text('TokyoDome'), findsOneWidget);
      expect(find.text('ARASHI'), findsOneWidget);
      expect(find.textContaining('閲覧のみ'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '参加する'));
      await tester.pumpAndSettle();

      expect(repo.joined, contains('tok1'));
      expect(find.text('GENBA-DETAIL'), findsOneWidget);
    });

    testWidgets('無効化済みの招待は理由を表示する', (tester) async {
      await pumpJoin(
        tester,
        const InvitePreview(
          valid: false,
          reason: 'invite_revoked',
          genbaId: 'g9',
        ),
      );
      expect(find.text('この招待リンクは無効化されています'), findsOneWidget);
    });
  });

  group('招待リンク貼り付け画面', () {
    testWidgets('不正な入力はエラーを表示する', (tester) async {
      final db = await signedInTestDb();
      addTearDown(db.close);
      await pumpScreen(
        tester,
        db: db,
        clock: clock,
        child: const InvitePasteScreen(),
      );

      await tester.enterText(find.byType(TextField), 'これはリンクではない');
      await tester.tap(find.widgetWithText(FilledButton, '参加へ進む'));
      await tester.pumpAndSettle();

      expect(find.text('招待リンクまたはコードを正しく入力してください'), findsOneWidget);
    });
  });
}
