// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/date_only.dart';

part 'oshi.freezed.dart';
part 'oshi.g.dart';

/// 推し区分（§9）。
enum OshiRank {
  @JsonValue('saioshi')
  saioshi,
  @JsonValue('oshi')
  oshi,
  @JsonValue('yuruoshi')
  yuruoshi,
  @JsonValue('hakooshi')
  hakooshi,
  @JsonValue('curious')
  curious,
}

extension OshiRankLabel on OshiRank {
  String get label => switch (this) {
        OshiRank.saioshi => '最推し',
        OshiRank.oshi => '推し',
        OshiRank.yuruoshi => 'ゆる推し',
        OshiRank.hakooshi => '箱推し',
        OshiRank.curious => '気になる',
      };
}

/// グループ／アーティスト。
@freezed
abstract class OshiGroup with _$OshiGroup {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory OshiGroup({
    required String id,
    required String ownerId,
    required String name,
    String? kind,

    /// 推しカラー（#RRGGBB）。アクセントのみに使用しコントラストを壊さない。
    String? color,
    String? memo,

    /// グループ画像の端末内参照（`images/<owner>/oshi/...`）。
    /// 同期対象外（Outbox/Supabase へ送らない, H-04）。写真なしはイニシャル
    /// フォールバック（design-spec §10/§12.1）。
    String? imageLocalPath,

    /// グループ画像の代替説明（読み上げ用, §14・同期対象）。
    String? imageAltText,

    /// グループ単位のお気に入り（design-spec §10/§12.1・同期対象）。
    @Default(false) bool isFavorite,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _OshiGroup;

  factory OshiGroup.fromJson(Map<String, dynamic> json) =>
      _$OshiGroupFromJson(json);
}

@freezed
abstract class OshiMember with _$OshiMember {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory OshiMember({
    required String id,
    required String groupId,
    required String ownerId,
    required String name,
    @Default(OshiRank.oshi) OshiRank rank,
    String? color,
    @NullableDateOnlyConverter() DateTime? oshiSince,
    @NullableDateOnlyConverter() DateTime? birthday,
    String? memo,

    /// 推し画像の端末内参照（`images/<owner>/oshi/...`）。
    /// 同期対象外（Outbox/Supabase へ送らない, H-04）。他端末では表示されない。
    String? imageLocalPath,

    /// 推し画像の代替説明（読み上げ用, §14・同期対象）。
    String? imageAltText,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _OshiMember;

  factory OshiMember.fromJson(Map<String, dynamic> json) =>
      _$OshiMemberFromJson(json);
}

/// ユーザー定義の記念日（design-spec §10/§12.1）。
///
/// グループに属し、任意でメンバーに紐づく。誕生日（[OshiMember.birthday]）や
/// 推し始めた日（[OshiMember.oshiSince]）とは別に、ユーザーが自由に登録する
/// 記念日を正規化して保持する。毎年の記念日として月日で次回発生を導出する。
@freezed
abstract class OshiAnniversary with _$OshiAnniversary {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory OshiAnniversary({
    required String id,
    required String ownerId,
    required String groupId,

    /// 任意でメンバーに紐づける（null = グループ全体の記念日）。
    String? memberId,
    required String label,

    /// 記念日の日付。毎年の記念日は月日で次回発生を導出する。
    @DateOnlyConverter() required DateTime date,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _OshiAnniversary;

  factory OshiAnniversary.fromJson(Map<String, dynamic> json) =>
      _$OshiAnniversaryFromJson(json);
}

/// グループとメンバーの集約ビュー。
@freezed
abstract class OshiGroupWithMembers with _$OshiGroupWithMembers {
  const factory OshiGroupWithMembers({
    required OshiGroup group,
    @Default(<OshiMember>[]) List<OshiMember> members,
  }) = _OshiGroupWithMembers;
}
