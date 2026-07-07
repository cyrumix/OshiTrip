// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/images/image_upload_status.dart';
import '../../../core/time/date_only.dart';

part 'itinerary_plan.freezed.dart';
part 'itinerary_plan.g.dart';

/// 現場の計画（旅程）。1現場につき既定で1件作成できるが、DBは将来の複数
/// 旅程に備えて1対多を許容する（itinerary-plan-spec.md §2.1）。
///
/// 公演会場・開場・開演・終演は [Genba] から導出する固定アンカーであり、
/// 計画自身のフィールドとして重複保存しない（§3.1/§12.1）。
@freezed
abstract class ItineraryPlan with _$ItineraryPlan {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory ItineraryPlan({
    required String id,
    required String genbaId,
    required String ownerId,
    required String title,
    String? memo,

    /// 旅程の日付範囲（任意）。未設定は「期間未定」を表す。
    @NullableDateOnlyConverter() DateTime? startDate,
    @NullableDateOnlyConverter() DateTime? endDate,

    /// 旅程の基準タイムゾーン（IANA形式、既定は端末タイムゾーンだが domain
    /// 自体は端末設定に依存しない。§2.6）。
    required String timeZoneId,
    String? coverImageLocalPath,
    String? coverImageStoragePath,
    @Default(ImageUploadStatus.localOnly)
    ImageUploadStatus coverImageUploadStatus,
    @Default(0) int sortOrder,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _ItineraryPlan;

  factory ItineraryPlan.fromJson(Map<String, dynamic> json) =>
      _$ItineraryPlanFromJson(json);
}
