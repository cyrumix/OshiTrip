import 'itinerary_leg.dart' show ItineraryTravelMode;
import 'itinerary_value_origin.dart';
import 'shared_facility.dart'
    show FacilityModerationStatus, facilityModerationStatusFromCode;

/// 権利確認済み共有概算経路（Supabase `shared_route_estimates` / 0027）の
/// **Flutter側再利用**を安全に閉じ込める純粋ドメイン層（旅程Phase 4 残タスク）。
///
/// 現状、共有概算経路の**UI表示（旅程スポット→施設ID解決→パネル表示）は未実装**
/// で、次Phaseへ持ち越す（施設ID解決に必要な shared_facilities のFlutter
/// クライアントが D-209 で次Phase送りのため）。ただし将来の再利用を「安全に」
/// 実装するための**強制ゲート**を、shared_facility.dart（D-209）と同じ先出し方針で
/// ここに用意する。再利用の読み取りは必ず [parseSharedRouteEstimate] を通し、
/// 次の不変条件を満たさない行を採用しない:
///
/// - `moderation_status = 'approved'`（承認済み＝共有）のみ再利用できる。
/// - `data_origin` は権利根拠を説明できる4種（[ItineraryValueOrigin]）に限る。
///   'google' 等は列挙に存在しないため**型で表現できず**、Google応答をそのまま
///   再利用元にできない（ADR-0010 §7 / D-179 / D-216）。
/// - `rights_basis`（権利根拠の説明）が非空。
///
/// owner 境界はサーバー（RLS: approved は全認証ユーザー閲覧可・下書きは本人のみ）
/// で強制する。この純粋層はそれと同じ不変条件をクライアント側でも二重化する
/// （多層防御）。Google Routes のライブ応答はここへ入れない（別DTO
/// [RouteLiveResult]・恒久保存しない, D-215）。

/// 再利用可能な共有概算経路の1件（再利用に必要な最小フィールド）。
class SharedRouteEstimate {
  const SharedRouteEstimate({
    required this.id,
    required this.originFacilityId,
    required this.destinationFacilityId,
    required this.travelMode,
    required this.representativeTimeBucket,
    required this.dataOrigin,
    required this.rightsBasis,
    this.distanceMeters,
    this.durationMinutes,
    this.routeSummary,
    this.fareAmountMinor,
    this.fareCurrency,
  });

  final String id;
  final String? originFacilityId;
  final String? destinationFacilityId;
  final ItineraryTravelMode travelMode;
  final String? representativeTimeBucket;

  /// 承認済みのため必ず4種のいずれか（Google応答由来ではない）。
  final ItineraryValueOrigin dataOrigin;

  /// 承認済みのため必ず非空（権利根拠の説明）。
  final String rightsBasis;

  final int? distanceMeters;
  final int? durationMinutes;
  final String? routeSummary;
  final int? fareAmountMinor;
  final String? fareCurrency;
}

/// 共有概算経路の**再利用可否**を判定する純粋関数。再利用してよければ null、
/// だめなら理由を返す（shared_facility.dart の invariant と同じ設計）。
///
/// dataOrigin は型（[ItineraryValueOrigin]）で4種に限定済みのため、ここでは
/// approved かつ rights_basis 非空だけを検査する。呼び出し側（[parseSharedRouteEstimate]）
/// は、行の data_origin 文字列が4種でなければ**この関数に到達する前に**採用を
/// 却下する（'google' 等を弾く）。
String? sharedRouteEstimateReuseError({
  required FacilityModerationStatus status,
  required String? rightsBasis,
}) {
  if (status != FacilityModerationStatus.approved) {
    return '共有概算経路の再利用は承認済み(approved)に限ります';
  }
  final basis = rightsBasis?.trim() ?? '';
  if (basis.isEmpty) {
    return '共有概算経路の再利用には権利根拠(rights_basis)が必要です';
  }
  return null;
}

/// `shared_route_estimates` の Supabase 行（JSON）を、再利用可能な
/// [SharedRouteEstimate] へ**防御的に**変換する。再利用の不変条件
/// （[sharedRouteEstimateReuseError]）を満たさない行・欠損行・想定外の
/// data_origin/travel_mode は **null**（採用しない）。
///
/// これにより「approved のみ」「data_origin/rights_basis を守る」「Google応答を
/// 再利用元にしない」を、UI/Repository がどこから呼んでも一箇所で強制できる。
SharedRouteEstimate? parseSharedRouteEstimate(Map<String, dynamic> row) {
  final id = row['id'];
  if (id is! String || id.isEmpty) return null;

  final status = facilityModerationStatusFromCodeForRoute(
    row['moderation_status'] as String?,
  );
  final dataOrigin = _valueOriginFromCode(row['data_origin'] as String?);
  final travelMode = _travelModeFromCode(row['travel_mode'] as String?);
  // data_origin/travel_mode が想定外（'google' 等）なら採用しない。
  if (dataOrigin == null || travelMode == null) return null;

  final rightsBasis = row['rights_basis'] as String?;
  if (sharedRouteEstimateReuseError(
        status: status,
        rightsBasis: rightsBasis,
      ) !=
      null) {
    return null;
  }

  return SharedRouteEstimate(
    id: id,
    originFacilityId: row['origin_facility_id'] as String?,
    destinationFacilityId: row['destination_facility_id'] as String?,
    travelMode: travelMode,
    representativeTimeBucket: row['representative_time_bucket'] as String?,
    dataOrigin: dataOrigin,
    rightsBasis: rightsBasis!.trim(),
    distanceMeters: (row['distance_meters'] as num?)?.toInt(),
    durationMinutes: (row['duration_minutes'] as num?)?.toInt(),
    routeSummary: row['route_summary'] as String?,
    fareAmountMinor: (row['fare_amount_minor'] as num?)?.toInt(),
    fareCurrency: row['fare_currency'] as String?,
  );
}

/// `moderation_status` 文字列 → [FacilityModerationStatus]（route_estimates も
/// 同じ4状態を使うため facility の判定を再利用する）。
FacilityModerationStatus facilityModerationStatusFromCodeForRoute(
  String? code,
) =>
    facilityModerationStatusFromCode(code);

/// `data_origin` 文字列 → [ItineraryValueOrigin]。4種以外（'google' 等）は null。
ItineraryValueOrigin? _valueOriginFromCode(String? code) => switch (code) {
      'user_provided' => ItineraryValueOrigin.userProvided,
      'facility_provided' => ItineraryValueOrigin.facilityProvided,
      'open_data' => ItineraryValueOrigin.openData,
      'licensed' => ItineraryValueOrigin.licensed,
      _ => null,
    };

/// `travel_mode` 文字列 → [ItineraryTravelMode]（Routes対応4手段）。他は null。
ItineraryTravelMode? _travelModeFromCode(String? code) => switch (code) {
      'walking' => ItineraryTravelMode.walking,
      'transit' => ItineraryTravelMode.transit,
      'driving' => ItineraryTravelMode.driving,
      'bicycling' => ItineraryTravelMode.bicycling,
      _ => null,
    };
