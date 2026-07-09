// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/date_only.dart';
import 'memo_content.dart';

part 'memo_template.freezed.dart';
part 'memo_template.g.dart';

/// メモテンプレート（よく使う中身のひな形）。Todo テンプレートと同じ思想で保存・
/// 再利用する（§7.7 改訂）。メモ種類 [kind] と、その種類に応じた雛形（タイトル・
/// 本文・[content]＝チェックリスト項目/BINGOサイズとマス文言/投票選択肢と重複可否）
/// を1行に持つ。テンプレートから作成したメモは独立コピーになり、テンプレートを
/// 後から編集しても作成済みメモは変わらない（適用時にコピーするため）。
@freezed
abstract class MemoTemplate with _$MemoTemplate {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoTemplate({
    required String id,
    required String ownerId,
    required String name,
    @Default(MemoKind.free) MemoKind kind,

    /// 既定テンプレートの区分（today_card の集合メモ等の識別に使う）。
    @Default(MemoCategory.other) MemoCategory category,
    @Default('') String title,
    @Default('') String body,

    /// 雛形の構造化コンテンツ（自由メモは null）。投票の票([MemoVote.votes])は
    /// 雛形には保存せず、適用時に空から始める。
    MemoContent? content,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _MemoTemplate;

  factory MemoTemplate.fromJson(Map<String, dynamic> json) =>
      _$MemoTemplateFromJson(json);
}
