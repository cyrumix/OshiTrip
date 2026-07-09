// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'memo_content.freezed.dart';
part 'memo_content.g.dart';

/// メモの種類（§7.7 改訂）。メモ種類は「メモの動き・UI・データ構造」を表す。
/// テンプレート（よく使う中身のひな形）とは分離する。既存メモは [free] 扱い。
enum MemoKind {
  /// 自由メモ: タイトルと本文を自由入力する（既存メモはこれ）。
  @JsonValue('free')
  free,

  /// チェックリスト: 項目を追加・編集・削除し、各項目にチェックを付ける。
  @JsonValue('checklist')
  checklist,

  /// BINGO: 3×3/4×4/5×5 のマス。タップで選択/解除、縦横斜めで BINGO 判定。
  @JsonValue('bingo')
  bingo,

  /// 投票: タイトル・説明＋複数選択肢。投票でき、重複投票の可否を選べる。
  @JsonValue('vote')
  vote,
}

extension MemoKindLabel on MemoKind {
  String get label => switch (this) {
        MemoKind.free => '自由メモ',
        MemoKind.checklist => 'チェックリスト',
        MemoKind.bingo => 'BINGO',
        MemoKind.vote => '投票',
      };

  /// 種類選択シートの短い説明（非エンジニア向け, §7.7 UI）。
  String get description => switch (this) {
        MemoKind.free => '感想や注意事項を自由に記録',
        MemoKind.checklist => '持ち物や購入予定をチェック',
        MemoKind.bingo => 'セトリ予想やファンサBINGOを作成',
        MemoKind.vote => '複数候補から投票で決める',
      };
}

/// レガシー/テンプレート由来のメモ区分（旧§7.7）。メモ種類([MemoKind])とは別軸で、
/// 既定テンプレートの識別（today_card の集合メモ表示など）に使う。[other] は
/// 「テンプレートを使わない」を表す。
enum MemoCategory {
  @JsonValue('free')
  free,
  @JsonValue('goods')
  goods,
  @JsonValue('meetup')
  meetup,
  @JsonValue('around')
  around,
  @JsonValue('notice')
  notice,
  @JsonValue('other')
  other,
}

extension MemoCategoryLabel on MemoCategory {
  /// 区分のラベル。
  String get label => switch (this) {
        MemoCategory.free => '自由メモ',
        MemoCategory.goods => '物販',
        MemoCategory.meetup => '集合場所',
        MemoCategory.around => '周辺施設',
        MemoCategory.notice => '注意事項',
        MemoCategory.other => 'メモ',
      };
}

/// チェックリストの1項目。
@freezed
abstract class MemoChecklistItem with _$MemoChecklistItem {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoChecklistItem({
    required String id,
    @Default('') String text,
    @Default(false) bool checked,
    @Default(0) int sortOrder,
  }) = _MemoChecklistItem;

  factory MemoChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$MemoChecklistItemFromJson(json);
}

/// BINGO の状態。[size]=3/4/5、[cells] は size×size のマス文言（行優先）、
/// [selected] は選択済みマスの添字（0..size*size-1）。
@freezed
abstract class MemoBingo with _$MemoBingo {
  const MemoBingo._();

  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoBingo({
    @Default(3) int size,
    @Default(<String>[]) List<String> cells,
    @Default(<int>[]) List<int> selected,
  }) = _MemoBingo;

  factory MemoBingo.fromJson(Map<String, dynamic> json) =>
      _$MemoBingoFromJson(json);

  /// マス総数。
  int get cellCount => size * size;

  /// 揃った列（縦・横・斜め）の数。複数揃えばその数を返す。
  int get lineCount {
    final n = size;
    if (n <= 0) return 0;
    final sel = selected.toSet();
    bool full(Iterable<int> idx) => idx.every(sel.contains);

    var count = 0;
    for (var r = 0; r < n; r++) {
      if (full([for (var c = 0; c < n; c++) r * n + c])) count++;
    }
    for (var c = 0; c < n; c++) {
      if (full([for (var r = 0; r < n; r++) r * n + c])) count++;
    }
    if (full([for (var i = 0; i < n; i++) i * n + i])) count++;
    if (full([for (var i = 0; i < n; i++) i * n + (n - 1 - i)])) count++;
    return count;
  }

  /// 1列でも揃っていれば BINGO。
  bool get hasBingo => lineCount > 0;

  /// マスの選択をトグルする（未選択→選択、選択→解除）。範囲外は無視する。
  MemoBingo toggle(int index) {
    if (index < 0 || index >= cellCount) return this;
    final next = [...selected];
    if (next.contains(index)) {
      next.removeWhere((i) => i == index);
    } else {
      next.add(index);
    }
    return copyWith(selected: next);
  }
}

/// 投票の選択肢。
@freezed
abstract class MemoVoteOption with _$MemoVoteOption {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoVoteOption({
    required String id,
    @Default('') String text,
    @Default(0) int sortOrder,
  }) = _MemoVoteOption;

  factory MemoVoteOption.fromJson(Map<String, dynamic> json) =>
      _$MemoVoteOptionFromJson(json);
}

/// 1票の記録（[voterId] は将来の複数ユーザー共有を見据えた設計。今は owner）。
@freezed
abstract class MemoVoteRecord with _$MemoVoteRecord {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoVoteRecord({
    required String voterId,
    required String optionId,
  }) = _MemoVoteRecord;

  factory MemoVoteRecord.fromJson(Map<String, dynamic> json) =>
      _$MemoVoteRecordFromJson(json);
}

/// 投票メモの状態。選択肢・投票・重複可否を持つ。SNS化や共有機能は作らないが、
/// 票は [MemoVoteRecord.voterId] 単位で保持し、将来の複数ユーザー投票へ拡張しや
/// すくしておく。
@freezed
abstract class MemoVote with _$MemoVote {
  const MemoVote._();

  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoVote({
    @Default('') String description,
    @Default(<MemoVoteOption>[]) List<MemoVoteOption> options,
    @Default(<MemoVoteRecord>[]) List<MemoVoteRecord> votes,

    /// 重複投票の可否。false=1人1票、true=同じ人が複数選択肢へ投票可。
    @Default(false) bool allowDuplicate,
  }) = _MemoVote;

  factory MemoVote.fromJson(Map<String, dynamic> json) =>
      _$MemoVoteFromJson(json);

  /// 選択肢ごとの得票数。
  int countFor(String optionId) =>
      votes.where((v) => v.optionId == optionId).length;

  /// [voterId] が [optionId] へ投票済みか。
  bool hasVoted(String voterId, String optionId) =>
      votes.any((v) => v.voterId == voterId && v.optionId == optionId);

  /// 投票をトグルする。既に同じ票があれば取り消す。無ければ追加する。
  /// [allowDuplicate]=false のときは、その voter の既存票を差し替える（1人1票）。
  /// true のときは同じ voter が複数選択肢へ投票できる。
  MemoVote castVote({required String voterId, required String optionId}) {
    if (hasVoted(voterId, optionId)) {
      return copyWith(
        votes: votes
            .where((v) => !(v.voterId == voterId && v.optionId == optionId))
            .toList(),
      );
    }
    if (!allowDuplicate) {
      // 1人1票: この voter の他の票を外してから追加する。
      return copyWith(
        votes: [
          ...votes.where((v) => v.voterId != voterId),
          MemoVoteRecord(voterId: voterId, optionId: optionId),
        ],
      );
    }
    return copyWith(
      votes: [...votes, MemoVoteRecord(voterId: voterId, optionId: optionId)],
    );
  }
}

/// メモの種類別の構造化コンテンツ（自由メモは title/body を使い、これは null）。
/// 1つの JSON として genba_memos.content（Drift=TEXT / Supabase=jsonb）へ保存する。
@freezed
abstract class MemoContent with _$MemoContent {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory MemoContent({
    @Default(<MemoChecklistItem>[]) List<MemoChecklistItem> checklist,
    MemoBingo? bingo,
    MemoVote? vote,
  }) = _MemoContent;

  factory MemoContent.fromJson(Map<String, dynamic> json) =>
      _$MemoContentFromJson(json);
}
