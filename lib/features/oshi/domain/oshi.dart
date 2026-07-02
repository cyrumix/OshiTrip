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
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _OshiMember;

  factory OshiMember.fromJson(Map<String, dynamic> json) =>
      _$OshiMemberFromJson(json);
}

/// グループとメンバーの集約ビュー。
@freezed
abstract class OshiGroupWithMembers with _$OshiGroupWithMembers {
  const factory OshiGroupWithMembers({
    required OshiGroup group,
    @Default(<OshiMember>[]) List<OshiMember> members,
  }) = _OshiGroupWithMembers;
}
