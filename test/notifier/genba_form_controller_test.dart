import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_form_controller.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  ProviderContainer createContainer({bool signedIn = true}) {
    final db = createTestDb();
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    if (signedIn) {
      // デモモードのローカル認証でログインしておく
      container.read(authRepositoryProvider);
    }
    return container;
  }

  Future<void> signInDemo(ProviderContainer container) async {
    final result = await container
        .read(authRepositoryProvider)
        .signIn(email: 'demo@example.com', password: 'demo-pass');
    expect(result.isOk, isTrue);
  }

  test('必須項目が欠けている間は submit がバリデーション失敗を返す', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    final result = await notifier.submit();
    expect(result.failureOrNull?.message, contains('日付'));
  });

  test('入力途中の内容が下書き保存され、再オープンで復元される', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier.mutate(
      (s) => s.copyWith(artistName: '推しグループ', title: '夏ライブ'),
    );
    // 自動保存の書き込みを待つ
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // 画面を離れて再度開いた想定（provider を破棄して再構築）
    container.invalidate(genbaFormControllerProvider(null));
    final restored =
        await container.read(genbaFormControllerProvider(null).future);
    expect(restored.artistName, '推しグループ');
    expect(restored.title, '夏ライブ');
    expect(restored.restoredFromDraft, isTrue);
  });

  test('遠征する→交通・宿泊が「必要」になる。しない→「不要」', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier.setExpedition(true);
    var state = container.read(genbaFormControllerProvider(null)).value!;
    expect(state.transportRequirement, RequirementStatus.required);
    expect(state.lodgingRequirement, RequirementStatus.required);

    notifier.setExpedition(false);
    state = container.read(genbaFormControllerProvider(null)).value!;
    expect(state.transportRequirement, RequirementStatus.notRequired);
    expect(state.lodgingRequirement, RequirementStatus.notRequired);
  });

  test('submit 成功で現場が保存され、下書きが消える', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier.mutate(
      (s) => s.copyWith(
        artistName: '推しグループ',
        title: '夏ライブ',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    final result = await notifier.submit();
    expect(result.isOk, isTrue);

    final all = await container.read(genbaRepositoryProvider).watchAll().first;
    expect(all.single.genba.title, '夏ライブ');

    // 下書きが消えている（再構築しても空のフォーム）
    container.invalidate(genbaFormControllerProvider(null));
    final fresh =
        await container.read(genbaFormControllerProvider(null).future);
    expect(fresh.title, isEmpty);
    expect(fresh.restoredFromDraft, isFalse);
  });

  test(
      '日程（公演日）を変更すると手動終演(manualEndedAt)は解除される'
      '（古い日程を前提にした値を持ち越さない, H-07）', () async {
    final container = createContainer();
    await signInDemo(container);
    // currentUserProvider（Stream由来）が実際に認証済みへ遷移するまで待つ。
    // authRepositoryProvider.signIn 自体は同期的に _current を更新するが、
    // それを watch している localDataScopeProvider 等はストリーム経由で
    // 1マイクロタスク遅れて反映されるため、直接 Repository を呼ぶこの
    // テストでは明示的に待つ必要がある（フォーム経由のテストは
    // GenbaFormController.build 内の await が暗黙にこれを行っている）。
    final user = await container.read(currentUserProvider.future);
    final ownerId = user!.id;

    // 手動終演済みの既存現場を用意する。
    final original = makeGenba(
      id: 'g-reschedule',
      ownerId: ownerId,
      eventDate: DateTime(2026, 6, 1),
      startTimeMinutes: 18 * 60,
      endTimeMinutes: 21 * 60,
      manualEndedAt: DateTime(2026, 6, 1, 20, 30).toUtc(),
    );
    final upsert =
        await container.read(genbaRepositoryProvider).upsertGenba(original);
    expect(upsert.isOk, isTrue);

    final notifier =
        container.read(genbaFormControllerProvider('g-reschedule').notifier);
    await container.read(genbaFormControllerProvider('g-reschedule').future);

    // 日程を未来へ変更して保存する。
    notifier.mutate((s) => s.copyWith(eventDate: DateTime(2026, 9, 1)));
    final result = await notifier.submit();
    expect(result.isOk, isTrue);

    final saved = await container
        .read(genbaRepositoryProvider)
        .watchById('g-reschedule')
        .first;
    expect(saved!.genba.eventDate, DateTime(2026, 9, 1));
    // 古い日程の手動終演を持ち越さない。再導出できる状態に戻る。
    expect(saved.genba.manualEndedAt, isNull);
  });

  test('日程を変更しない編集では手動終演(manualEndedAt)は保持される', () async {
    final container = createContainer();
    await signInDemo(container);
    final user = await container.read(currentUserProvider.future);
    final ownerId = user!.id;

    final manualEndedAt = DateTime(2026, 6, 1, 20, 30).toUtc();
    final original = makeGenba(
      id: 'g-keep',
      ownerId: ownerId,
      eventDate: DateTime(2026, 6, 1),
      startTimeMinutes: 18 * 60,
      endTimeMinutes: 21 * 60,
      manualEndedAt: manualEndedAt,
    );
    final upsert =
        await container.read(genbaRepositoryProvider).upsertGenba(original);
    expect(upsert.isOk, isTrue);

    final notifier =
        container.read(genbaFormControllerProvider('g-keep').notifier);
    await container.read(genbaFormControllerProvider('g-keep').future);

    // 会場だけ変更（日程は変えない）。
    notifier.mutate((s) => s.copyWith(venue: '新しい会場'));
    final result = await notifier.submit();
    expect(result.isOk, isTrue);

    final saved =
        await container.read(genbaRepositoryProvider).watchById('g-keep').first;
    expect(saved!.genba.venue, '新しい会場');
    expect(saved.genba.manualEndedAt, manualEndedAt);
  });

  test('未ログインでは submit が AuthFailure', () async {
    final container = createContainer(signedIn: false);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier.mutate(
      (s) => s.copyWith(
        artistName: 'a',
        title: 't',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    final result = await notifier.submit();
    expect(result.failureOrNull?.message, contains('ログイン'));
  });
}
