// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/result.dart';
import '../../../core/time/date_only.dart';

part 'performance.freezed.dart';
part 'performance.g.dart';

/// ユーザー投稿型公演マスタ（§10）。
///
/// 今回は「境界と土台」のみ: エンティティ・Repository抽象・現場からの
/// `performanceId` 紐づけ・サーバースキーマまで。検索UI・重複統合・
/// 登録者数集計・通報は docs/follow-up-work.md 参照。
@freezed
abstract class Performance with _$Performance {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Performance({
    required String id,
    required String groupName,
    required String title,
    required String venue,
    @DateOnlyConverter() required DateTime eventDate,
    int? startTimeMinutes,
    String? createdBy,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _Performance;

  factory Performance.fromJson(Map<String, dynamic> json) =>
      _$PerformanceFromJson(json);
}

/// 公演マスタのリポジトリ抽象（境界のみ・UIからは未使用）。
abstract interface class PerformanceRepository {
  /// インクリメンタル検索（後続実装。候補順: 完全一致→登録者数→日付近さ）。
  Future<Result<List<Performance>>> search(String query);

  Future<Result<Performance?>> findById(String id);

  /// 新規公演の投稿（重複候補提示は後続実装）。
  Future<Result<Performance>> submit(Performance performance);
}
