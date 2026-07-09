import 'memo_content.dart';
import 'memo_template.dart';

/// 既定メモテンプレート（アプリ定数・DB 非保存）。すべて種類は「自由メモ」。
/// 名前は §7.7 改訂の指定（自由メモ/物販/集合/周辺施設/注意事項）。区分は旧
/// テンプレート互換（today_card の集合メモ表示など）に合わせる。
class MemoTemplatePreset {
  const MemoTemplatePreset({
    required this.presetId,
    required this.name,
    required this.kind,
    required this.category,
    this.title = '',
    this.body = '',
    this.content,
  });

  final String presetId;
  final String name;
  final MemoKind kind;
  final MemoCategory category;
  final String title;
  final String body;
  final MemoContent? content;
}

/// 初期テンプレート5件（すべて自由メモ）。
const List<MemoTemplatePreset> kMemoTemplatePresets = [
  MemoTemplatePreset(
    presetId: 'preset.memo.free',
    name: '自由メモ',
    kind: MemoKind.free,
    category: MemoCategory.free,
    title: '自由メモ',
  ),
  MemoTemplatePreset(
    presetId: 'preset.memo.goods',
    name: '物販',
    kind: MemoKind.free,
    category: MemoCategory.goods,
    title: '物販',
  ),
  MemoTemplatePreset(
    presetId: 'preset.memo.meetup',
    name: '集合',
    kind: MemoKind.free,
    category: MemoCategory.meetup,
    title: '集合場所',
  ),
  MemoTemplatePreset(
    presetId: 'preset.memo.around',
    name: '周辺施設',
    kind: MemoKind.free,
    category: MemoCategory.around,
    title: '周辺施設',
  ),
  MemoTemplatePreset(
    presetId: 'preset.memo.notice',
    name: '注意事項',
    kind: MemoKind.free,
    category: MemoCategory.notice,
    title: '注意事項',
  ),
];

/// 指定した種類のプリセット（プリセットは全て自由メモなので、free 以外は空）。
List<MemoTemplatePreset> memoPresetsOfKind(MemoKind kind) =>
    kMemoTemplatePresets.where((p) => p.kind == kind).toList();

/// テンプレート選択 UI 用に、プリセットとユーザー保存テンプレートを1つの型へ
/// 正規化したビュー。
class MemoTemplateOption {
  const MemoTemplateOption({
    required this.id,
    required this.name,
    required this.kind,
    required this.category,
    required this.isPreset,
    this.title = '',
    this.body = '',
    this.content,
  });

  final String id;
  final String name;
  final MemoKind kind;
  final MemoCategory category;
  final bool isPreset;
  final String title;
  final String body;
  final MemoContent? content;

  factory MemoTemplateOption.fromPreset(MemoTemplatePreset p) =>
      MemoTemplateOption(
        id: p.presetId,
        name: p.name,
        kind: p.kind,
        category: p.category,
        isPreset: true,
        title: p.title,
        body: p.body,
        content: p.content,
      );

  factory MemoTemplateOption.fromTemplate(MemoTemplate t) => MemoTemplateOption(
        id: t.id,
        name: t.name,
        kind: t.kind,
        category: t.category,
        isPreset: false,
        title: t.title,
        body: t.body,
        content: t.content,
      );
}
