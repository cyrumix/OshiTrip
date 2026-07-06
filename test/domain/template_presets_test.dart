import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/templates/domain/template_presets.dart';

/// 標準プリセット（アプリ内の読み取り専用データ）の内容・件数を検証する。
void main() {
  test('標準プリセットは各種別ちょうど1件（Todo/持ち物）', () {
    expect(presetsOfType(TodoItemType.todo), hasLength(1));
    expect(presetsOfType(TodoItemType.belonging), hasLength(1));
    expect(kAllPresets, hasLength(2));
  });

  test('Todoプリセットは仕様どおりの名称・項目', () {
    final preset = presetsOfType(TodoItemType.todo).single;
    expect(preset.name, 'ライブ・イベントの基本準備');
    expect(preset.itemType, TodoItemType.todo);
    expect(preset.items.map((i) => i.name), [
      'チケットの受取・発券・表示を確認する',
      '本人確認と入場条件を確認する',
      '会場までのルートと出発時刻を確認する',
      '終演後の帰宅経路・最終便を確認する',
      '公式案内と持ち込みルールを確認する',
      'グッズ販売の時間と決済方法を確認する',
      'スマホ・モバイルバッテリーを充電する',
      '当日の服装・靴・天気を確認する',
    ]);
  });

  test('持ち物プリセットは仕様どおりの名称・項目', () {
    final preset = presetsOfType(TodoItemType.belonging).single;
    expect(preset.name, 'ライブ・イベントの基本持ち物');
    expect(preset.itemType, TodoItemType.belonging);
    expect(preset.items, hasLength(12));
    expect(preset.items.first.name, 'チケット');
    expect(preset.items.last.name, '折りたたみバッグ');
    // 持ち物プリセットは重要度を持たない。
    expect(preset.items.every((i) => i.priority == null), isTrue);
  });

  test('プリセットは安定したIDとバージョンを持つ（将来の内容更新に備える）', () {
    expect(kLiveTodoPreset.presetId, 'preset.todo.live_basic');
    expect(kLiveBelongingPreset.presetId, 'preset.belonging.live_basic');
    expect(kLiveTodoPreset.version, greaterThanOrEqualTo(1));
    expect(kLiveBelongingPreset.version, greaterThanOrEqualTo(1));
  });

  test('TemplateOption 化してもプリセットが標準フラグ付きで表現される', () {
    final option = TemplateOption.fromPreset(kLiveTodoPreset);
    expect(option.isPreset, isTrue);
    expect(option.presetVersion, kLiveTodoPreset.version);
    expect(option.items, hasLength(kLiveTodoPreset.items.length));
  });
}
