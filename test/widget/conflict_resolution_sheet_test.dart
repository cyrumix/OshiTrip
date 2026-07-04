import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/auth/local_data_scope.dart';
import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/sync/conflict_resolver.dart';
import 'package:oshi_trip/core/sync/outbox_operation.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/core/widgets/conflict_resolution_sheet.dart';

/// 競合解決シート（R8-A）: 実データの競合一覧が表示され、「サーバーを採用」は
/// 確認ダイアログを経て resolver を呼び、「この端末の変更で再送」も resolver を
/// 呼ぶことを、実UIで検証する。resolver は fake に差し替えて呼び出しを記録する。
///
/// [useServerResult]/[keepLocalResult] を差し替えると失敗（[Err]）も注入できる。
/// 失敗時は競合一覧から取り除かない（未解決のまま残る挙動を模す）。
class _FakeConflictResolver implements ConflictResolver {
  final List<String> useServerCalls = [];
  final List<String> keepLocalCalls = [];
  List<OutboxOperation> conflictList;
  Result<ConflictResolutionResult> useServerResult =
      const Ok(ConflictResolutionResult.resolved);
  Result<ConflictResolutionResult> keepLocalResult =
      const Ok(ConflictResolutionResult.resolved);

  _FakeConflictResolver(this.conflictList);

  @override
  Future<List<OutboxOperation>> conflicts({required String ownerId}) async =>
      conflictList;

  @override
  Future<Result<ConflictResolutionResult>> useServer(
    String mutationId, {
    required String ownerId,
  }) async {
    useServerCalls.add(mutationId);
    if (useServerResult.isOk) {
      conflictList = conflictList
          .where((o) => o.mutationId != mutationId)
          .toList(growable: false);
    }
    return useServerResult;
  }

  @override
  Future<Result<ConflictResolutionResult>> keepLocal(
    String mutationId, {
    required String ownerId,
  }) async {
    keepLocalCalls.add(mutationId);
    if (keepLocalResult.isOk) {
      conflictList = conflictList
          .where((o) => o.mutationId != mutationId)
          .toList(growable: false);
    }
    return keepLocalResult;
  }
}

void main() {
  final clock = FixedClock(DateTime.utc(2026, 7, 2, 12));

  OutboxOperation conflictOp(String id, String table) => OutboxOperation(
        mutationId: id,
        ownerId: 'user-1',
        entityTable: table,
        entityId: 'e-$id',
        opType: OutboxOpType.upsert,
        payload: {'id': 'e-$id'},
        status: OutboxStatus.conflict,
        createdAt: clock.now(),
        updatedAt: clock.now(),
      );

  Future<void> pumpSheet(
    WidgetTester tester,
    _FakeConflictResolver fake,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDataScopeProvider.overrideWithValue(
            const LocalDataScopeAuthenticated('user-1'),
          ),
          conflictResolverProvider.overrideWithValue(fake),
          conflictsProvider.overrideWith((ref) async => fake.conflictList),
        ],
        child: MaterialApp(
          // ink_sparkle.frag/Vulkan の既知環境制約を避けるため、テストハーネス
          // 側だけ InkRipple へ差し替える（本番テーマは変更しない, D-159）。
          theme: ThemeData(splashFactory: InkRipple.splashFactory),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showConflictResolutionSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('競合一覧が表示され、種別ラベルが出る', (tester) async {
    final fake = _FakeConflictResolver([
      conflictOp('m1', SyncEntity.todos),
      conflictOp('m2', SyncEntity.genbas),
    ]);
    await pumpSheet(tester, fake);

    expect(find.text('同期の競合を解決'), findsOneWidget);
    expect(find.text('Todoの変更が競合しています'), findsOneWidget);
    expect(find.text('現場の変更が競合しています'), findsOneWidget);
    expect(find.text('サーバーを採用'), findsNWidgets(2));
    expect(find.text('この端末の変更で再送'), findsNWidgets(2));
  });

  testWidgets('「サーバーを採用」は確認ダイアログを経て resolver.useServer を呼ぶ', (tester) async {
    final fake = _FakeConflictResolver([conflictOp('m1', SyncEntity.todos)]);
    await pumpSheet(tester, fake);

    await tester.tap(find.text('サーバーを採用'));
    await tester.pumpAndSettle();
    // 確認ダイアログが出る（破棄の警告）。
    expect(find.text('サーバーの内容を採用'), findsOneWidget);
    expect(find.textContaining('破棄'), findsWidgets);

    // キャンセルでは呼ばれない。
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(fake.useServerCalls, isEmpty);

    // もう一度開いて破棄確定 → useServer が呼ばれる。
    await tester.tap(find.text('サーバーを採用'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄して採用'));
    await tester.pumpAndSettle();
    expect(fake.useServerCalls, ['m1']);
  });

  testWidgets('「この端末の変更で再送」は確認なしで resolver.keepLocal を呼ぶ', (tester) async {
    final fake = _FakeConflictResolver([conflictOp('m1', SyncEntity.genbas)]);
    await pumpSheet(tester, fake);

    await tester.tap(find.text('この端末の変更で再送'));
    await tester.pumpAndSettle();
    expect(fake.keepLocalCalls, ['m1']);
    expect(fake.useServerCalls, isEmpty);
  });

  testWidgets('サーバー採用が失敗すると理由と再試行を表示し、成功メッセージは出さない', (tester) async {
    final fake = _FakeConflictResolver([conflictOp('m1', SyncEntity.genbas)])
      ..useServerResult = const Err(NetworkFailure());
    await pumpSheet(tester, fake);

    await tester.tap(find.text('サーバーを採用'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄して採用'));
    await tester.pumpAndSettle();

    expect(fake.useServerCalls, ['m1']);
    // 失敗理由 + 再試行を促す SnackBar が出る。
    expect(find.textContaining('通信に失敗'), findsOneWidget);
    expect(find.textContaining('再試行してください'), findsOneWidget);
    // 「競合を解決しました」は絶対に出さない。
    expect(find.text('競合を解決しました'), findsNothing);
    // 競合は残ったまま（ボタンは再度押せる = busy が解除されている）。
    expect(find.text('サーバーを採用'), findsOneWidget);
  });

  testWidgets('再送失敗（Err）でも成功表示せず、競合行は残る', (tester) async {
    final fake = _FakeConflictResolver([conflictOp('m1', SyncEntity.genbas)])
      ..keepLocalResult =
          const Err(NetworkFailure(message: '同期を完了できませんでした。接続を確認して再試行してください'));
    await pumpSheet(tester, fake);

    await tester.tap(find.text('この端末の変更で再送'));
    await tester.pumpAndSettle();

    expect(fake.keepLocalCalls, ['m1']);
    expect(find.textContaining('同期を完了できませんでした'), findsOneWidget);
    expect(find.text('競合を解決しました'), findsNothing);
    // 競合行は残り、再試行できる。
    expect(find.text('この端末の変更で再送'), findsOneWidget);
  });

  testWidgets('成功時は「競合を解決しました」を表示し、競合行が消える', (tester) async {
    final fake = _FakeConflictResolver([conflictOp('m1', SyncEntity.genbas)]);
    await pumpSheet(tester, fake);

    await tester.tap(find.text('サーバーを採用'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('破棄して採用'));
    await tester.pumpAndSettle();

    expect(fake.useServerCalls, ['m1']);
    expect(find.text('競合を解決しました'), findsOneWidget);
    // 競合は解消し、一覧から消える。
    expect(find.text('現場の変更が競合しています'), findsNothing);
  });
}
