import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/storage/kv_store.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_providers.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/domain/genba_preparation.dart';
import 'package:oshi_trip/features/templates/application/template_actions.dart';
import 'package:oshi_trip/features/templates/application/template_providers.dart';
import 'package:oshi_trip/features/templates/domain/template_presets.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

/// テンプレート適用/保存を実配線（Drift + 実 Repository, デモ認証）で検証する。
/// - 適用後に持ち物残数・準備状態が更新される
/// - 重複は追加せず件数で知らせる
/// - 現在の項目から名前付きテンプレートを保存できる（プリセットとは別管理）
void main() {
  const ownerId = 'demo-user-1';
  const genbaId = 'g-tpl';
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  Future<AppDatabase> signedInDb() async {
    final db = createTestDb();
    final kv = DriftKvStore(db);
    await kv.put(KvKeys.tutorialDone, '1');
    await kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': ownerId, 'email': 'demo@example.com'}),
    );
    return db;
  }

  Future<ProviderContainer> container(AppDatabase db) async {
    final c = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
        nowProvider.overrideWith((ref) => Stream.value(clock.now())),
      ],
    );
    addTearDown(c.dispose);
    // デモ認証を復元して owner を確定させる。
    await c.read(currentUserProvider.future);
    return c;
  }

  Future<GenbaAggregate> aggregate(ProviderContainer c) async {
    final a = await c.read(genbaRepositoryProvider).watchById(genbaId).first;
    return a!;
  }

  test('持ち物プリセット適用で持ち物残数・準備状態が更新される', () async {
    final db = await signedInDb();
    addTearDown(db.close);
    final c = await container(db);
    await c.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
              id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
        );

    final preset = TemplateOption.fromPreset(kLiveBelongingPreset);
    final result = await c.read(templateActionsProvider).applyTemplate(
      genbaId: genbaId,
      itemType: TodoItemType.belonging,
      selected: preset.items,
      existing: const [],
    );

    expect(result.isOk, isTrue);
    final outcome = result.valueOrNull!;
    expect(outcome.added, 12);
    expect(outcome.skipped, 0);

    final a = await aggregate(c);
    // 持ち物残数が更新され、Todo残数には混ざらない。
    expect(a.incompleteBelongingCount, 12);
    expect(a.incompleteTodoCount, 0);
    // 準備状態は「未対応」（未チェックの持ち物あり）になる。
    expect(GenbaPreparation.of(a).belonging, BelongingPrepState.pending);
  });

  test('同じテンプレートを再適用しても重複追加されない（件数で知らせる）', () async {
    final db = await signedInDb();
    addTearDown(db.close);
    final c = await container(db);
    await c.read(genbaRepositoryProvider).upsertGenba(
          makeGenba(
              id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
        );
    final preset = TemplateOption.fromPreset(kLiveBelongingPreset);
    final actions = c.read(templateActionsProvider);

    await actions.applyTemplate(
      genbaId: genbaId,
      itemType: TodoItemType.belonging,
      selected: preset.items,
      existing: const [],
    );
    final a1 = await aggregate(c);

    final again = await actions.applyTemplate(
      genbaId: genbaId,
      itemType: TodoItemType.belonging,
      selected: preset.items,
      existing: a1.todos,
    );
    expect(again.valueOrNull!.added, 0);
    expect(again.valueOrNull!.skipped, 12);

    final a2 = await aggregate(c);
    expect(a2.incompleteBelongingCount, 12); // 増えていない
  });

  test('現在のTodoから名前付きテンプレートを保存でき、プリセットと別に一覧へ出る', () async {
    final db = await signedInDb();
    addTearDown(db.close);
    final c = await container(db);
    final genbaRepo = c.read(genbaRepositoryProvider);
    await genbaRepo.upsertGenba(
      makeGenba(id: genbaId, ownerId: ownerId, eventDate: DateTime(2026, 8, 1)),
    );
    await genbaRepo.upsertTodo(
      makeTodo(
        id: 't1',
        genbaId: genbaId,
        ownerId: ownerId,
        name: 'うちわを作る',
        type: TodoItemType.todo,
        isDone: true,
        priority: TodoPriority.high,
      ),
    );
    final a = await aggregate(c);
    final todos = a.todos.where((t) => t.type == TodoItemType.todo).toList();

    final saved = await c.read(templateActionsProvider).saveCurrentAsTemplate(
          name: '定番Todo',
          itemType: TodoItemType.todo,
          todos: todos,
        );
    expect(saved.isOk, isTrue);

    final userTemplates = await c.read(userTemplatesProvider.future);
    expect(userTemplates, hasLength(1));
    final t = userTemplates.single;
    expect(t.template.name, '定番Todo');
    expect(t.template.itemType, TodoItemType.todo);
    // 重要度は保存され、完了状態は保存されない（テンプレートに完了は無い）。
    expect(t.items.single.name, 'うちわを作る');
    expect(t.items.single.priority, TodoPriority.high);

    // オプション一覧では標準プリセット + このユーザーテンプレートが並ぶ。
    final options = c.read(templateOptionsProvider(TodoItemType.todo));
    expect(options.where((o) => o.isPreset), hasLength(1));
    expect(
        options.where((o) => !o.isPreset && o.name == '定番Todo'), hasLength(1));
  });
}
