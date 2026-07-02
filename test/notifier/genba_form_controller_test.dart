import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_expedition/core/providers.dart';
import 'package:oshi_expedition/core/time/clock.dart';
import 'package:oshi_expedition/features/genba/application/genba_form_controller.dart';
import 'package:oshi_expedition/features/genba/domain/genba.dart';

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
