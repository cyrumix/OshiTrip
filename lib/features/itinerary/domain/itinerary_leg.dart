// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/date_only.dart';
import 'itinerary_value_origin.dart';

part 'itinerary_leg.freezed.dart';
part 'itinerary_leg.g.dart';

/// 移動区間データの取得元（itinerary-plan-spec.md §6.3）。
///
/// [googleRoutes] は Google Routes のライブ応答を「一時表示」した区間を示す
/// 区分であり、経路概要・所要時間・運賃などを恒久キャッシュ（共有再利用）
/// する許可を意味しない。永続する概算経路値の権利根拠は
/// [ItineraryLeg.valueOrigin] で別途表す（D-180/D-181）。書面許諾等が無い限り
/// Google 応答値を永続 entity へ暗黙変換しない。
enum ItineraryLegSource {
  @JsonValue('manual')
  manual,
  @JsonValue('google_routes')
  googleRoutes,
}

/// 移動手段（§6.1）。
enum ItineraryTravelMode {
  @JsonValue('walking')
  walking,
  @JsonValue('transit')
  transit,
  @JsonValue('driving')
  driving,
  @JsonValue('bicycling')
  bicycling,
  @JsonValue('taxi')
  taxi,
  @JsonValue('flight')
  flight,
  @JsonValue('other')
  other,
}

extension ItineraryTravelModeLabel on ItineraryTravelMode {
  String get label => switch (this) {
        ItineraryTravelMode.walking => '徒歩',
        ItineraryTravelMode.transit => '公共交通',
        ItineraryTravelMode.driving => '車',
        ItineraryTravelMode.bicycling => '自転車',
        ItineraryTravelMode.taxi => 'タクシー',
        ItineraryTravelMode.flight => '飛行機',
        ItineraryTravelMode.other => 'その他',
      };
}

/// スポット間の移動区間（§6.2）。[originEntryId] / [destinationEntryId] は
/// [ItineraryEntry.id] を参照する（互いに異なる項目でなければならない）。
///
/// 運賃は [fareAmountMinor]（最小通貨単位、例: 円なら1円単位）と
/// [fareCurrency] を組で扱い、どちらか一方だけの設定は許可しない（§6.2）。
@freezed
abstract class ItineraryLeg with _$ItineraryLeg {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory ItineraryLeg({
    required String id,
    required String planId,
    required String ownerId,
    required String originEntryId,
    required String destinationEntryId,
    @Default(ItineraryLegSource.manual) ItineraryLegSource source,
    @Default(ItineraryTravelMode.other) ItineraryTravelMode travelMode,
    @NullableUtcDateTimeConverter() DateTime? departureAt,
    @NullableUtcDateTimeConverter() DateTime? arrivalAt,
    int? durationMinutes,
    int? distanceMeters,
    int? fareAmountMinor,
    String? fareCurrency,
    String? routeSummary,

    /// 永続する概算経路値（所要時間・距離・運賃・経路概要）の出典・権利根拠。
    /// 既定はユーザー入力。Google 応答の無許可キャッシュではなく、手動または
    /// 保存権限を持つ情報源の概算値であることを表す（§12.5, D-180）。
    @Default(ItineraryValueOrigin.userProvided)
    ItineraryValueOrigin valueOrigin,
    String? rightsBasis,

    /// 概算経路の代表時刻帯（例: 平日朝ラッシュ）と最終確認日時（§12.5）。
    String? representativeTimeBucket,
    @NullableUtcDateTimeConverter() DateTime? lastVerifiedAt,

    /// 公共交通の路線・停留所・乗換ステップ（Phase 1では不透明なJSON文字列
    /// として保持し、構造化パースは後続Phaseで扱う）。
    String? transitStepsJson,
    String? encodedPolyline,
    String? googleMapsUrl,
    @NullableUtcDateTimeConverter() DateTime? fetchedAt,
    String? cacheKey,
    @Default(false) bool isStale,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _ItineraryLeg;

  factory ItineraryLeg.fromJson(Map<String, dynamic> json) =>
      _$ItineraryLegFromJson(json);
}

/// 金額（円。JPYは補助単位=円なので [fareAmountMinor] をそのまま円で扱う）を
/// 「1,200円」のように3桁区切りで表示する（item 4。通貨は日本円前提）。
String formatJpyYen(int yen) {
  final s = yen.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '${yen < 0 ? '-' : ''}$buf円';
}
