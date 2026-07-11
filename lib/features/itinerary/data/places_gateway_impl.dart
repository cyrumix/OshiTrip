import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';
import '../domain/place_attribution.dart';
import '../domain/places_gateway.dart';

/// places-proxy Edge Function 呼び出しの薄い応答（旅程Phase 3 / ADR-0010 §3）。
///
/// [RoutesProxyResponse] と同じ設計。2xx なら [data]（デコード済み JSON）を、
/// 非2xx なら [errorKind]（Edge Function の `{error: kind}`）を持つ。
class PlacesProxyResponse {
  const PlacesProxyResponse({required this.status, this.data, this.errorKind});

  final int status;
  final Map<String, dynamic>? data;
  final String? errorKind;

  bool get isSuccess => status >= 200 && status < 300 && data != null;
}

/// places-proxy Edge Function を呼ぶトランスポート境界。SupabaseClient への
/// 直接依存をここへ閉じ込め、[PlacesGatewayImpl] を Supabase 非依存で単体
/// テストできるようにする（`SupabaseRoutesProxyTransport` と同じ設計）。
abstract interface class PlacesProxyTransport {
  Future<PlacesProxyResponse> invoke(Map<String, dynamic> body);
}

/// `Supabase Functions` 経由で places-proxy を呼ぶトランスポート実装。
///
/// Web Service 用 Google API キーはアプリに埋め込まず、places-proxy（サーバー）が
/// 保持する（ADR-0010 §3）。ここは認証済み Supabase クライアント経由で Edge
/// Function を呼ぶだけ。共通タイムアウト（[withRemoteTimeout]）を課す。
class SupabasePlacesProxyTransport implements PlacesProxyTransport {
  SupabasePlacesProxyTransport(this._client);

  final SupabaseClient _client;

  @override
  Future<PlacesProxyResponse> invoke(Map<String, dynamic> body) async {
    try {
      final res = await _client.functions
          .invoke('places-proxy', body: body)
          .withRemoteTimeout();
      final data = res.data;
      return PlacesProxyResponse(
        status: res.status,
        data: data is Map ? data.cast<String, dynamic>() : null,
      );
    } on FunctionException catch (e) {
      final details = e.details;
      final kind = details is Map ? details['error'] as String? : null;
      return PlacesProxyResponse(status: e.status, errorKind: kind);
    }
  }
}

/// places-proxy の `{error: kind}` を型付き [Failure] へ変換する純粋関数。
/// kind が不明なときは HTTP status で概略判定する。UI は [UnavailableFailure] /
/// エラーのとき手動入力へ縮退する（§8.2）。
Failure placesProxyErrorToFailure(String? kind, int status) {
  switch (kind) {
    case 'unauthorized':
      return const AuthFailure(message: 'ログインが必要です');
    case 'rate_limited':
      return const NetworkFailure(
        message: '施設検索の回数上限に達しました。しばらくしてから再試行してください',
      );
    case 'unavailable':
      return const UnavailableFailure();
    case 'invalid_request':
      return const ValidationFailure('施設検索のリクエスト条件が無効です');
    case 'timeout':
    case 'upstream_error':
      return const NetworkFailure(message: '施設検索に失敗しました。時間をおいて再試行してください');
    default:
      if (status == 401 || status == 403) {
        return const AuthFailure(message: 'ログインが必要です');
      }
      if (status == 429) {
        return const NetworkFailure(
          message: '施設検索の回数上限に達しました。しばらくしてから再試行してください',
        );
      }
      if (status == 400) {
        return const ValidationFailure('施設検索のリクエスト条件が無効です');
      }
      if (status == 503) return const UnavailableFailure();
      return const NetworkFailure(message: '施設検索に失敗しました');
  }
}

/// [PlacesGateway] の実装。Autocomplete / Place Details のリクエストを
/// places-proxy の JSON payload へ変換し、応答を一時DTOへ変換する（旅程Phase 3）。
///
/// - Google API キーはアプリに埋め込まない（places-proxy が保持, ADR-0010 §3）。
/// - Google 応答は一時DTO（[PlaceSuggestion]/[PlaceDetails]）としてのみ返し、
///   名称・住所を永続 entity へ自動転記しない（D-178/D-179。永続してよいのは
///   Place ID のみ）。
class PlacesGatewayImpl implements PlacesGateway {
  PlacesGatewayImpl({required PlacesProxyTransport transport})
      : _transport = transport;

  final PlacesProxyTransport _transport;

  @override
  Future<Result<List<PlaceSuggestion>>> autocomplete({
    required String input,
    required PlacesSessionToken sessionToken,
    PlacesLocationBias? bias,
  }) async {
    final body = <String, dynamic>{
      'action': 'autocomplete',
      'input': input,
      'sessionToken': sessionToken.value,
      if (bias != null) 'locationBias': _biasJson(bias),
    };
    try {
      final res = await _transport.invoke(body);
      if (res.isSuccess) return Ok(_suggestionsFrom(res.data!));
      return Err(placesProxyErrorToFailure(res.errorKind, res.status));
    } on TimeoutException catch (e) {
      return Err(NetworkFailure(cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  @override
  Future<Result<PlaceDetails>> placeDetails({
    required String placeId,
    required PlacesSessionToken sessionToken,
  }) async {
    final body = <String, dynamic>{
      'action': 'details',
      'placeId': placeId,
      'sessionToken': sessionToken.value,
    };
    try {
      final res = await _transport.invoke(body);
      if (res.isSuccess) return Ok(_detailsFrom(res.data!));
      return Err(placesProxyErrorToFailure(res.errorKind, res.status));
    } on TimeoutException catch (e) {
      return Err(NetworkFailure(cause: e));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  /// Google Places (New) の locationBias 形（circle）へ変換する。
  static Map<String, dynamic> _biasJson(PlacesLocationBias bias) => {
        'circle': {
          'center': {'latitude': bias.latitude, 'longitude': bias.longitude},
          'radius': bias.radiusMeters,
        },
      };

  /// 欠落フィールドがあってもクラッシュしないよう防御的に変換する。
  static List<PlaceSuggestion> _suggestionsFrom(Map<String, dynamic> data) {
    final raw = data['suggestions'];
    if (raw is! List) return const [];
    final out = <PlaceSuggestion>[];
    for (final s in raw) {
      if (s is Map) {
        final placeId = s['placeId'] as String?;
        if (placeId == null || placeId.isEmpty) continue;
        out.add(
          PlaceSuggestion(
            placeId: placeId,
            primaryText: (s['primaryText'] as String?) ?? '',
            secondaryText: s['secondaryText'] as String?,
          ),
        );
      }
    }
    return out;
  }

  static PlaceDetails _detailsFrom(Map<String, dynamic> data) => PlaceDetails(
        placeId: (data['placeId'] as String?) ?? '',
        displayName: data['displayName'] as String?,
        formattedAddress: data['formattedAddress'] as String?,
        attributions: parsePlaceAttributions(data['attributions']),
      );
}
