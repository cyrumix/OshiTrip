import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import 'itinerary_leg.dart';

/// Google Routes への経路取得の外部境界（ADR-0010 §1、旅程Phase 4）。
///
/// **登録スポット↔スポットの区間のみ**を対象にする（itinerary-plan-spec §6
/// 冒頭「登録スポット間の権利確認済み概算経路」）。transport/lodging/note を
/// 終端とする区間は対象外とし、既存の手動入力のみを維持する。
///
/// このモジュールは Google 応答を「一時 DTO」（[RouteLiveResult]）として表す。
/// 永続 [ItineraryLeg] や共有概算経路DBへは、書面許諾等が無い限り暗黙保存しない
/// （D-180/D-181）。呼び出しは「経路詳細を開く」「最新ルートを更新」の明示操作
/// からのみ行うこと（初期表示・並び替え・保存だけでは呼ばない, §6.3/§8.3）。
abstract interface class RoutesGateway {
  Future<Result<RouteLiveResult>> computeRoute(RouteLiveRequest request);
}

/// 経路取得の1地点。Google Place ID があればそれを最優先し、無ければ緯度経度を
/// 使う。スポットに座標もPlace IDも無い場合、呼び出し側はリクエストを組み立て
/// られない（[hasLocation]=false → 手動入力へ縮退, itinerary-plan-spec §13）。
class RouteEndpoint {
  const RouteEndpoint({this.placeId, this.latitude, this.longitude});

  final String? placeId;
  final double? latitude;
  final double? longitude;

  bool get hasLocation =>
      (placeId != null && placeId!.isNotEmpty) ||
      (latitude != null && longitude != null);

  /// single-flight・stale判定用の安定した地点識別子（[routeRequestFingerprint]
  /// が利用する）。Place ID優先、次いで座標。
  String get signature {
    if (placeId != null && placeId!.isNotEmpty) return 'place:$placeId';
    if (latitude != null && longitude != null) {
      return 'latlng:${latitude!.toStringAsFixed(6)},'
          '${longitude!.toStringAsFixed(6)}';
    }
    return 'unknown';
  }

  @override
  bool operator ==(Object other) =>
      other is RouteEndpoint &&
      other.placeId == placeId &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(placeId, latitude, longitude);
}

/// 経路取得リクエスト（スポット↔スポットのみ）。
class RouteLiveRequest {
  const RouteLiveRequest({
    required this.origin,
    required this.destination,
    required this.travelMode,
    required this.representativeDepartureUtc,
  });

  final RouteEndpoint origin;
  final RouteEndpoint destination;

  /// walking/transit/driving/bicycling のみ対応（taxi/flight/other は既存の
  /// 手動入力のまま, itinerary-plan-spec §6.1）。
  final ItineraryTravelMode travelMode;

  /// 公共交通のリクエスト条件に使う代表出発日時（UTC）。徒歩・車・自転車では
  /// 所要時間算出のヒントとして送るのみで結果を左右する必須条件ではない。
  final DateTime representativeDepartureUtc;
}

/// Google Routes のライブ応答（一時DTO）。itinerary-plan-spec §6.2 の最小範囲に
/// 限定する: 所要時間・距離・任意運賃・公共交通の路線/乗換概要。
/// polyline・座標等の追加取得はしない（Field Mask allowlistで強制,
/// [kRoutesAllowedFields]）。
///
/// Places の応答とは異なり、Routes API は `attributions[]` をレスポンスへ
/// 含めない。帰属（「Google Maps」表示）は Google の表示ポリシーに基づき
/// 呼び出し側（`route_live_panel.dart`）が固定文言として描画する
/// （developers.google.com/maps/documentation/routes/policies, 2026-07-09確認）。
class RouteLiveResult {
  const RouteLiveResult({
    required this.durationMinutes,
    required this.distanceMeters,
    this.walkMinutes = 0,
    this.fareText,
    this.transitSteps = const [],
    required this.requestedAt,
  });

  final int durationMinutes;
  final int distanceMeters;

  /// 徒歩ステップの合計所要（分）。「徒歩 合計N分」の表示に使う（item 4）。
  final int walkMinutes;

  /// 運賃の表示テキスト（取得できた場合のみ非null。§6.2「金額は取得・保存が
  /// 許される場合のみ」— ここでは表示専用で永続保存しない）。
  final String? fareText;

  final List<RouteLiveTransitStep> transitSteps;

  /// このライブ結果を取得した日時（UTC）。画面状態としてのみ保持し永続保存しない。
  final DateTime requestedAt;
}

/// 公共交通の1ステップ（路線名・行き先・乗降停留所・発着時刻）。
class RouteLiveTransitStep {
  const RouteLiveTransitStep({
    required this.lineName,
    this.lineNameShort,
    this.vehicleType,
    this.headsign,
    this.departureStopName,
    this.arrivalStopName,
    this.departureTime,
    this.arrivalTime,
  });

  final String lineName;
  final String? lineNameShort;
  final String? vehicleType;
  final String? headsign;
  final String? departureStopName;
  final String? arrivalStopName;

  /// ローカライズ済みの発車・到着時刻テキスト（「10:30」等。item 4）。
  final String? departureTime;
  final String? arrivalTime;
}

/// Google 未設定・無効・利用不可時のゲートウェイ。常に [UnavailableFailure]。
/// これを既定にすることで、Routes 未接続でも呼び出し側が型で縮退でき、
/// Phase 1〜3 の手動フローを一切壊さない（ADR-0010 §1）。
class UnavailableRoutesGateway implements RoutesGateway {
  const UnavailableRoutesGateway();

  @override
  Future<Result<RouteLiveResult>> computeRoute(
    RouteLiveRequest request,
  ) async =>
      const Err(UnavailableFailure());
}

/// 2地点を結ぶ Google Maps の外部リンクをアプリ側で生成する（追加の Routes 取得
/// をせずに外部地図導線を提供する, ADR-0010 §4/itinerary-plan-spec §6.2）。
/// どちらかの地点に位置情報が無ければ生成できない（null）。
Uri? googleMapsDirectionsUrl(RouteEndpoint origin, RouteEndpoint destination) {
  if (!origin.hasLocation || !destination.hasLocation) return null;
  // origin/destination は text（座標優先、無ければ Place ID）で渡し、Place ID は
  // *_place_id で併記する（Google 公式の dir api=1 形式。`place_id:` 接頭辞は
  // この形式では正しく解釈されない, item 5）。
  String text(RouteEndpoint e) {
    if (e.latitude != null && e.longitude != null) {
      return '${e.latitude},${e.longitude}';
    }
    return e.placeId ?? '';
  }

  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': text(origin),
    if (origin.placeId != null && origin.placeId!.isNotEmpty)
      'origin_place_id': origin.placeId!,
    'destination': text(destination),
    if (destination.placeId != null && destination.placeId!.isNotEmpty)
      'destination_place_id': destination.placeId!,
  });
}
