import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';
import '../../../core/time/clock.dart';
import '../domain/itinerary_leg.dart';
import '../domain/routes_gateway.dart';

/// routes-proxy Edge Function 呼び出しの薄い応答（旅程Phase 4 / ADR-0010 §3）。
///
/// トランスポート境界（[RoutesProxyTransport]）が返す、Supabase 非依存の
/// 値オブジェクト。2xx なら [data]（デコード済み JSON）を、非2xx なら
/// [errorKind]（Edge Function の `{error: kind}`）を持つ。
class RoutesProxyResponse {
  const RoutesProxyResponse({required this.status, this.data, this.errorKind});

  final int status;
  final Map<String, dynamic>? data;
  final String? errorKind;

  bool get isSuccess => status >= 200 && status < 300 && data != null;
}

/// routes-proxy Edge Function を呼ぶトランスポート境界。SupabaseClient への
/// 直接依存をここへ閉じ込め、[RoutesGatewayImpl] を Supabase 非依存で単体
/// テストできるようにする（`SupabaseMutationTransport` と同じ設計）。
abstract interface class RoutesProxyTransport {
  /// 成功/HTTPエラー応答は [RoutesProxyResponse] として返す。トランスポート層
  /// の失敗（timeout・通信断）は例外をそのまま投げる（呼び出し側が
  /// [NetworkFailure] へ変換する）。
  Future<RoutesProxyResponse> invoke(Map<String, dynamic> body);
}

/// `Supabase Functions` 経由で routes-proxy を呼ぶトランスポート実装。
///
/// Web Service 用 Google API キーはアプリに埋め込まず、routes-proxy（サーバー）
/// が保持する（ADR-0010 §3）。ここは認証済み Supabase クライアント経由で
/// Edge Function を呼ぶだけ。共通タイムアウト（[withRemoteTimeout]）を課す
/// （R8-C の通信タイムアウト方針）。
class SupabaseRoutesProxyTransport implements RoutesProxyTransport {
  SupabaseRoutesProxyTransport(this._client);

  final SupabaseClient _client;

  @override
  Future<RoutesProxyResponse> invoke(Map<String, dynamic> body) async {
    try {
      final res = await _client.functions
          .invoke('routes-proxy', body: body)
          .withRemoteTimeout();
      final data = res.data;
      return RoutesProxyResponse(
        status: res.status,
        data: data is Map ? data.cast<String, dynamic>() : null,
      );
    } on FunctionException catch (e) {
      // Edge Function は非2xx で {error: kind} を返す。invoke はこれを
      // FunctionException として投げ、details に本文が入る。
      final details = e.details;
      final kind = details is Map ? details['error'] as String? : null;
      return RoutesProxyResponse(status: e.status, errorKind: kind);
    }
  }
}

/// routes-proxy Edge Function の `{error: kind}` を型付き [Failure] へ変換する
/// 純粋関数（旅程Phase 4）。kind が不明なときは HTTP status で概略判定する。
Failure routesProxyErrorToFailure(String? kind, int status) {
  switch (kind) {
    case 'not_entitled':
      return const PermissionFailure(message: '最新ルートの取得はプレミアム限定の機能です');
    case 'unauthorized':
      return const AuthFailure(message: 'ログインが必要です');
    case 'rate_limited':
      return const NetworkFailure(
        message: '経路取得の回数上限に達しました。しばらくしてから再試行してください',
      );
    case 'invalid_request':
      return const ValidationFailure('経路を取得できませんでした（リクエスト条件が無効です）');
    case 'unavailable':
      return const UnavailableFailure();
    case 'timeout':
    case 'upstream_error':
      return const NetworkFailure(message: '経路の取得に失敗しました。時間をおいて再試行してください');
    default:
      if (status == 401 || status == 403) {
        return const PermissionFailure(message: '最新ルートを取得する権限がありません');
      }
      if (status == 429) {
        return const NetworkFailure(
          message: '経路取得の回数上限に達しました。しばらくしてから再試行してください',
        );
      }
      if (status == 400) {
        return const ValidationFailure('経路を取得できませんでした（リクエスト条件が無効です）');
      }
      return const NetworkFailure(message: '経路の取得に失敗しました');
  }
}

/// [RoutesGateway] の実装。[RouteLiveRequest] を routes-proxy の JSON payload へ
/// 変換し、応答を [RouteLiveResult] へ変換する（旅程Phase 4 / 修正1）。
///
/// - Google API キーはアプリに埋め込まない（routes-proxy が保持, ADR-0010 §3）。
/// - Google のライブ応答は一時 DTO（[RouteLiveResult]）としてのみ返し、
///   [ItineraryLeg] や共有DBへ永続保存しない（呼び出し側で保存しない設計,
///   D-215）。
/// - taxi/flight/other は Google Routes 非対応のため、送信せず
///   [ValidationFailure] を返す（手動入力のまま, §6.1・費用制御）。
class RoutesGatewayImpl implements RoutesGateway {
  RoutesGatewayImpl({
    required RoutesProxyTransport transport,
    required Clock clock,
  })  : _transport = transport,
        _clock = clock;

  final RoutesProxyTransport _transport;
  final Clock _clock;

  @override
  Future<Result<RouteLiveResult>> computeRoute(RouteLiveRequest request) async {
    final wireMode = _wireTravelMode(request.travelMode);
    if (wireMode == null) {
      return const Err(ValidationFailure('この移動手段はGoogle Routesでは取得できません'));
    }
    final body = <String, dynamic>{
      'origin': _endpointJson(request.origin),
      'destination': _endpointJson(request.destination),
      'travelMode': wireMode,
      'representativeDepartureUtc':
          request.representativeDepartureUtc.toUtc().toIso8601String(),
    };
    try {
      final res = await _transport.invoke(body);
      if (res.isSuccess) {
        // requestedAt は受信時刻をUTCで付与する（一時的な取得時刻。永続保存しない）。
        return Ok(_resultFrom(res.data!, _clock.now().toUtc()));
      }
      return Err(routesProxyErrorToFailure(res.errorKind, res.status));
    } on TimeoutException catch (e) {
      return Err(NetworkFailure(cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  static String? _wireTravelMode(ItineraryTravelMode mode) => switch (mode) {
        ItineraryTravelMode.walking => 'walking',
        ItineraryTravelMode.transit => 'transit',
        ItineraryTravelMode.driving => 'driving',
        ItineraryTravelMode.bicycling => 'bicycling',
        ItineraryTravelMode.taxi ||
        ItineraryTravelMode.flight ||
        ItineraryTravelMode.other =>
          null,
      };

  static Map<String, dynamic> _endpointJson(RouteEndpoint e) {
    if (e.placeId != null && e.placeId!.isNotEmpty) {
      return {'placeId': e.placeId};
    }
    return {'latitude': e.latitude, 'longitude': e.longitude};
  }

  /// 欠落フィールドがあってもクラッシュしないよう、防御的に変換する
  /// （APIレスポンス欠落耐性, 修正1テスト観点）。
  static RouteLiveResult _resultFrom(
    Map<String, dynamic> data,
    DateTime requestedAt,
  ) {
    final steps = <RouteLiveTransitStep>[];
    final rawSteps = data['transitSteps'];
    if (rawSteps is List) {
      for (final s in rawSteps) {
        if (s is Map) {
          steps.add(
            RouteLiveTransitStep(
              lineName: (s['lineName'] as String?) ?? '',
              lineNameShort: s['lineNameShort'] as String?,
              vehicleType: s['vehicleType'] as String?,
              headsign: s['headsign'] as String?,
              departureStopName: s['departureStopName'] as String?,
              arrivalStopName: s['arrivalStopName'] as String?,
            ),
          );
        }
      }
    }
    return RouteLiveResult(
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      distanceMeters: (data['distanceMeters'] as num?)?.toInt() ?? 0,
      fareText: data['fareText'] as String?,
      transitSteps: steps,
      requestedAt: requestedAt,
    );
  }
}
