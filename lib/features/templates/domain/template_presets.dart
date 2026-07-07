import '../../genba/domain/genba.dart';
import 'todo_template.dart';

/// アプリ標準プリセット（変更・削除不可の読み取り専用データ）。
///
/// ユーザーDBへ複製せず、アプリ内の定数として管理する。将来内容を更新できる
/// よう [presetId]（安定した識別子）と [version] を持たせる（適用済みかどうかの
/// 判定や、将来のマイグレーションで利用できるようにするため）。
class TemplatePreset {
  const TemplatePreset({
    required this.presetId,
    required this.version,
    required this.name,
    required this.itemType,
    required this.items,
  });

  /// 安定したプリセット識別子（名称変更に依存しない）。
  final String presetId;

  /// プリセット内容のバージョン。内容更新時にインクリメントする。
  final int version;
  final String name;
  final TodoItemType itemType;
  final List<TemplatePresetItem> items;
}

class TemplatePresetItem {
  const TemplatePresetItem({
    required this.name,
    this.priority,
    this.memo,
  });

  final String name;

  /// Todo プリセットのみ重要度を持つ（持ち物は null）。
  final TodoPriority? priority;
  final String? memo;
}

/// Todo の標準プリセット「ライブ・イベントの基本準備」。
const kLiveTodoPreset = TemplatePreset(
  presetId: 'preset.todo.live_basic',
  version: 1,
  name: 'ライブ・イベントの基本準備',
  itemType: TodoItemType.todo,
  items: [
    TemplatePresetItem(name: 'チケットの受取・発券・表示を確認する'),
    TemplatePresetItem(name: '本人確認と入場条件を確認する'),
    TemplatePresetItem(name: '会場までのルートと出発時刻を確認する'),
    TemplatePresetItem(name: '終演後の帰宅経路・最終便を確認する'),
    TemplatePresetItem(name: '公式案内と持ち込みルールを確認する'),
    TemplatePresetItem(name: 'グッズ販売の時間と決済方法を確認する'),
    TemplatePresetItem(name: 'スマホ・モバイルバッテリーを充電する'),
    TemplatePresetItem(name: '当日の服装・靴・天気を確認する'),
  ],
);

/// 持ち物の標準プリセット「ライブ・イベントの基本持ち物」。
const kLiveBelongingPreset = TemplatePreset(
  presetId: 'preset.belonging.live_basic',
  version: 1,
  name: 'ライブ・イベントの基本持ち物',
  itemType: TodoItemType.belonging,
  items: [
    TemplatePresetItem(name: 'チケット'),
    TemplatePresetItem(name: 'スマートフォン'),
    TemplatePresetItem(name: '身分証明書'),
    TemplatePresetItem(name: '財布・現金・決済手段'),
    TemplatePresetItem(name: 'モバイルバッテリー・充電ケーブル'),
    TemplatePresetItem(name: '飲み物'),
    TemplatePresetItem(name: 'ハンカチ・ティッシュ'),
    TemplatePresetItem(name: '常備薬'),
    TemplatePresetItem(name: 'ペンライト・応援グッズ'),
    TemplatePresetItem(name: 'ペンライトの予備電池'),
    TemplatePresetItem(name: 'タオル'),
    TemplatePresetItem(name: '折りたたみバッグ'),
  ],
);

/// 全標準プリセット（各種別1件）。
const kAllPresets = <TemplatePreset>[kLiveTodoPreset, kLiveBelongingPreset];

/// 指定種別の標準プリセット一覧（各種別1件だが将来増える可能性に備え List）。
List<TemplatePreset> presetsOfType(TodoItemType type) =>
    kAllPresets.where((p) => p.itemType == type).toList(growable: false);

/// テンプレート選択UIで、標準プリセットとユーザーテンプレートを同一に扱う
/// ための正規化ビューモデル。
class TemplateOption {
  const TemplateOption({
    required this.id,
    required this.name,
    required this.itemType,
    required this.isPreset,
    required this.items,
    this.presetVersion,
  });

  /// プリセットの場合は presetId、ユーザーテンプレートの場合はテンプレート id。
  final String id;
  final String name;
  final TodoItemType itemType;

  /// true = 標準プリセット（閲覧・適用のみ、編集・削除不可）。
  final bool isPreset;
  final int? presetVersion;
  final List<TemplateOptionItem> items;

  factory TemplateOption.fromPreset(TemplatePreset preset) => TemplateOption(
        id: preset.presetId,
        name: preset.name,
        itemType: preset.itemType,
        isPreset: true,
        presetVersion: preset.version,
        items: [
          for (final item in preset.items)
            TemplateOptionItem(
              name: item.name,
              priority: item.priority,
              memo: item.memo,
            ),
        ],
      );

  factory TemplateOption.fromUserTemplate(TodoTemplateWithItems t) =>
      TemplateOption(
        id: t.template.id,
        name: t.template.name,
        itemType: t.template.itemType,
        isPreset: false,
        items: [
          for (final item in t.sortedItems)
            TemplateOptionItem(
              name: item.name,
              priority: item.priority,
              memo: item.memo,
            ),
        ],
      );
}

class TemplateOptionItem {
  const TemplateOptionItem({
    required this.name,
    this.priority,
    this.memo,
  });

  final String name;
  final TodoPriority? priority;
  final String? memo;
}
