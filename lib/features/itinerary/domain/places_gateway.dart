import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import 'place_attribution.dart';

/// 施設検索の外部境界（ADR-0010 §1）。旅程ドメインを地図事業者へ依存させない
/// ための抽象。実装（Edge Function 経由の Google Places）は data 層に置き、
/// 未設定・障害・上限時は [UnavailableFailure] を返して手動フォールバックへ縮退する。
///
/// このモジュールは Google 応答を「一時 DTO」として表す。永続化してよい Google
/// 由来値は [PlaceSuggestion.placeId]/[PlaceDetails.placeId]（Place ID）だけであり、
/// 名称・住所は検索/選択画面の一時状態としてのみ扱う（§4.3/§12.2, D-178/D-179）。
abstract interface class PlacesGateway {
  /// 入力補完（Autocomplete New）。1検索セッション1[sessionToken]、3文字以上、
  /// [bias]（会場周辺）で件数を抑える。入力不足・無効時は呼び出し側が抑止する
  /// 前提だが、境界でも防御する。
  Future<Result<List<PlaceSuggestion>>> autocomplete({
    required String input,
    required PlacesSessionToken sessionToken,
    PlacesLocationBias? bias,
  });

  /// 候補選択後の詳細取得（Place Details New）。Autocomplete と**同じ**
  /// [sessionToken] を渡して1セッションを完了する。Field Mask は
  /// `id,displayName,formattedAddress,attributions` に限定される（実装側で強制）。
  Future<Result<PlaceDetails>> placeDetails({
    required String placeId,
    required PlacesSessionToken sessionToken,
  });
}

/// Autocomplete のセッショントークン（1検索セッションに1つ・UUIDv4・再利用禁止）。
/// 生成はアプリ側で行い、候補選択の Place Details まで同じ値を使う（ADR-0010 §5）。
class PlacesSessionToken {
  const PlacesSessionToken(this.value);
  final String value;

  @override
  bool operator ==(Object other) =>
      other is PlacesSessionToken && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PlacesSessionToken(***)'; // 値はログへ出さない
}

/// 検索の位置バイアス（会場周辺）。件数を抑え、無関係な遠隔候補を減らす。
class PlacesLocationBias {
  const PlacesLocationBias({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 30000,
  });
  final double latitude;
  final double longitude;
  final double radiusMeters;
}

/// Autocomplete 候補（一時 DTO）。永続化してよいのは [placeId] だけ。
/// [primaryText]/[secondaryText] は候補表示のための一時値（恒久保存しない）。
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    this.secondaryText,
  });
  final String placeId;
  final String primaryText;
  final String? secondaryText;
}

/// Place Details（一時 DTO）。Field Mask = id/displayName/formattedAddress/
/// attributions に対応。永続化してよいのは [placeId] のみ。名称・住所は画面の
/// 一時状態として扱い、永続 entity へ自動転記しない（ユーザーが独立入力した値を
/// user_provided として保存する, D-178/D-179）。
///
/// [attributions] は表示必須の帰属情報（構造化型 [PlaceAttribution]。provider を
/// 表示し、有効な https の providerUri だけを確認付きで開ける）。
///
/// HTTP Gateway → Dart の JSON 契約:
/// ```json
/// {
///   "placeId": "ChIJ...",
///   "displayName": "会場名" | null,
///   "formattedAddress": "住所" | null,
///   "attributions": [{"provider": "提供元", "providerUri": "https://..." | null}]
/// }
/// ```
/// attributions は [parsePlaceAttributions] で安全に変換する（不正 URI・巨大
/// 文字列・想定外オブジェクトは除外）。
class PlaceDetails {
  const PlaceDetails({
    required this.placeId,
    this.displayName,
    this.formattedAddress,
    this.attributions = const [],
  });
  final String placeId;
  final String? displayName;
  final String? formattedAddress;
  final List<PlaceAttribution> attributions;
}

/// Google 未設定・無効・利用不可時のゲートウェイ。常に [UnavailableFailure]。
/// これを既定にすることで、Places 未接続でも呼び出し側が型で縮退でき、Phase 2 の
/// 手動フローを一切壊さない（ADR-0010 §1）。
class UnavailablePlacesGateway implements PlacesGateway {
  const UnavailablePlacesGateway();

  @override
  Future<Result<List<PlaceSuggestion>>> autocomplete({
    required String input,
    required PlacesSessionToken sessionToken,
    PlacesLocationBias? bias,
  }) async =>
      const Err(UnavailableFailure());

  @override
  Future<Result<PlaceDetails>> placeDetails({
    required String placeId,
    required PlacesSessionToken sessionToken,
  }) async =>
      const Err(UnavailableFailure());
}

/// Place ID から Google Maps を開く URL をアプリ側で生成する（追加の Place Details
/// 取得をせずに外部地図導線を提供する, ADR-0010 §4/itinerary-plan-spec §4.3）。
/// 永続化可能な Google 識別子は Place ID だけなので、保存済み Place ID から
/// いつでも生成できる。
Uri googleMapsPlaceUrl(String placeId) => Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': placeId, 'query_place_id': placeId},
    );
