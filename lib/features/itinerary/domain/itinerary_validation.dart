import '../../../core/error/failure.dart';
import 'itinerary_entry.dart';
import 'itinerary_leg.dart';
import 'itinerary_plan.dart';
import 'itinerary_spot.dart';
import 'itinerary_spot_link.dart';
import 'itinerary_value_origin.dart';

/// 旅程ドメインの不変条件を検証する純粋関数群（itinerary-plan-spec.md §4/§6）。
///
/// すべて `Failure?`（null = 検証OK）を返す既存の規約
/// （[core/error/failure.dart] を参照する各種 Repository/Controller と同じ
/// 「nullは成功」の約束）に合わせる。副作用・I/Oは一切行わない。

/// 前後の余裕時間・所要時間として許容する上限（24時間）。
const int itineraryMaxBufferMinutes = 24 * 60;

/// URLとして許可するスキーム（§4.5「危険なスキームは拒否する」）。
const Set<String> itineraryAllowedUrlSchemes = {'http', 'https'};

/// ゆるいIANAタイムゾーン識別子の形（例: `Asia/Tokyo`, `UTC`）。
/// 実在するタイムゾーンDBとの厳密照合は行わない（追加の依存を避けるため）。
final RegExp _ianaLikePattern =
    RegExp(r'^[A-Za-z0-9_+\-]+(/[A-Za-z0-9_+\-]+)*$');

/// 緯度・経度は両方nullまたは両方有効値のときだけ許可する（§4.2）。
/// NaN / Infinity は「有効な座標」として扱わない（`< / >` 比較をすり抜けるため
/// `isFinite` を明示的に確認する）。
Failure? validateItineraryCoordinates(double? latitude, double? longitude) {
  if ((latitude == null) != (longitude == null)) {
    return const ValidationFailure('緯度と経度は両方指定するか、両方未設定にしてください');
  }
  if (latitude != null &&
      (!latitude.isFinite || latitude < -90 || latitude > 90)) {
    return const ValidationFailure('緯度は-90から90の範囲で指定してください');
  }
  if (longitude != null &&
      (!longitude.isFinite || longitude < -180 || longitude > 180)) {
    return const ValidationFailure('経度は-180から180の範囲で指定してください');
  }
  return null;
}

/// 終了日時は開始日時以後（日跨ぎは許可する。§5.2/§12.4）。
Failure? validateItineraryTimeRange(DateTime? start, DateTime? end) {
  if (start != null && end != null && end.isBefore(start)) {
    return const ValidationFailure('終了日時は開始日時以降にしてください');
  }
  return null;
}

/// 余裕時間・所要時間は0以上、かつ合理的な上限（24時間）以内（§5.4/§6.2）。
Failure? validateItineraryMinutes(int minutes, {required String label}) {
  if (minutes < 0) {
    return ValidationFailure('$labelは0以上にしてください');
  }
  if (minutes > itineraryMaxBufferMinutes) {
    return ValidationFailure('$labelは24時間（1440分）以内にしてください');
  }
  return null;
}

/// 距離は0以上（負値を許可しない）。
Failure? validateItineraryDistanceMeters(int? distanceMeters) {
  if (distanceMeters != null && distanceMeters < 0) {
    return const ValidationFailure('距離は0以上にしてください');
  }
  return null;
}

/// URLは許可スキーム（http/https）かつ host が存在するものだけ許可する
/// （§4.5「危険なスキームは拒否」＋ scheme だけの偽URL・host無しを弾く）。
Failure? validateItineraryUrl(String url, {String label = 'URL'}) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return ValidationFailure('$labelを入力してください');
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null ||
      !uri.hasScheme ||
      !itineraryAllowedUrlSchemes.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty) {
    return ValidationFailure('$labelはhttp/https形式の正しいURLを入力してください');
  }
  return null;
}

/// タイムゾーンIDの形を最小限検証する（空文字・明らかに不正な形を拒否する）。
Failure? validateItineraryTimeZoneId(String timeZoneId) {
  final trimmed = timeZoneId.trim();
  if (trimmed.isEmpty) {
    return const ValidationFailure('タイムゾーンを指定してください');
  }
  if (!_ianaLikePattern.hasMatch(trimmed)) {
    return const ValidationFailure('タイムゾーンはIANA形式で指定してください（例: Asia/Tokyo）');
  }
  return null;
}

/// 出典と権利根拠の整合（§12.2/§12.5, D-179）。[ItineraryValueOrigin
/// .userProvided] は [rightsBasis] 省略可。それ以外（facilityProvided /
/// openData / licensed）は、共有再利用の権利を説明できるよう空白除去後に
/// 非空の [rightsBasis] を必須にする。
Failure? validateItineraryRightsBasis(
  ItineraryValueOrigin origin,
  String? rightsBasis,
) {
  if (origin == ItineraryValueOrigin.userProvided) return null;
  if (rightsBasis == null || rightsBasis.trim().isEmpty) {
    return ValidationFailure('「${origin.label}」の出典には権利根拠(rights_basis)が必要です');
  }
  return null;
}

/// Phase 1 では Google Routes のライブ応答を永続 entity へ保存しない
/// （§12.5, D-180）。source=googleRoutes、または Google 応答固有の予約
/// フィールド（fetchedAt / cacheKey / encodedPolyline）が設定された leg を
/// 型付き [ValidationFailure] で拒否する。将来 Google から保存許諾を得た場合の
/// 解禁は別feature flag／Phase 4で扱い、ここでは先行解禁しない。
Failure? validateItineraryLegPhase1Persistable(ItineraryLeg leg) {
  final hasGoogleLiveArtifact = leg.source == ItineraryLegSource.googleRoutes ||
      leg.fetchedAt != null ||
      leg.cacheKey != null ||
      leg.encodedPolyline != null;
  if (hasGoogleLiveArtifact) {
    return const ValidationFailure(
      'Google Routesのライブ応答はこのフェーズでは保存できません（手動で入力してください）',
    );
  }
  return null;
}

/// 運賃は通貨と金額を組で扱う（片方だけの設定を許可しない。§6.2）。
Failure? validateItineraryFare(int? amountMinor, String? currency) {
  if ((amountMinor == null) != (currency == null)) {
    return const ValidationFailure('運賃は金額と通貨をどちらも指定するか、どちらも未設定にしてください');
  }
  if (amountMinor != null && amountMinor < 0) {
    return const ValidationFailure('運賃は0以上にしてください');
  }
  if (currency != null && currency.trim().isEmpty) {
    return const ValidationFailure('通貨コードを指定してください');
  }
  return null;
}

/// [ItineraryPlan] の不変条件をまとめて検証する。
Failure? validateItineraryPlan(ItineraryPlan plan) {
  if (plan.title.trim().isEmpty) {
    return const ValidationFailure('タイトルを入力してください');
  }
  final tz = validateItineraryTimeZoneId(plan.timeZoneId);
  if (tz != null) return tz;
  final range = validateItineraryTimeRange(plan.startDate, plan.endDate);
  if (range != null) return range;
  return null;
}

/// [ItinerarySpot] の不変条件をまとめて検証する（§4.2）。
/// URLフィールド（websiteUrl / googleMapsUrl）も危険スキームを拒否する。
Failure? validateItinerarySpot(ItinerarySpot spot) {
  if (spot.name.trim().isEmpty) {
    return const ValidationFailure('施設名を入力してください');
  }
  final coords = validateItineraryCoordinates(spot.latitude, spot.longitude);
  if (coords != null) return coords;
  final rights =
      validateItineraryRightsBasis(spot.dataOrigin, spot.rightsBasis);
  if (rights != null) return rights;
  if (spot.websiteUrl != null) {
    final f = validateItineraryUrl(spot.websiteUrl!, label: 'ウェブサイトURL');
    if (f != null) return f;
  }
  if (spot.googleMapsUrl != null) {
    final f =
        validateItineraryUrl(spot.googleMapsUrl!, label: 'Google Maps URL');
    if (f != null) return f;
  }
  return null;
}

/// [ItinerarySpotLink] の不変条件をまとめて検証する（§4.5）。
Failure? validateItinerarySpotLink(ItinerarySpotLink link) =>
    validateItineraryUrl(link.url, label: link.kind.label);

/// entry kind に対応する参照IDだけが設定されていることを検証する
/// （spot → spotId のみ、transport → transportId のみ、lodging → lodgingId
/// のみ、note → いずれも未設定。§5.1/§12.4）。
Failure? validateItineraryEntryReference(ItineraryEntry entry) {
  bool has(String? v) => v != null && v.trim().isNotEmpty;
  final refCount = [
    has(entry.spotId),
    has(entry.transportId),
    has(entry.lodgingId),
  ].where((v) => v).length;

  switch (entry.kind) {
    case ItineraryEntryKind.spot:
      if (!has(entry.spotId) || refCount != 1) {
        return const ValidationFailure(
          'spot種別の旅程項目にはspotIdだけを指定してください',
        );
      }
    case ItineraryEntryKind.transport:
      if (!has(entry.transportId) || refCount != 1) {
        return const ValidationFailure(
          'transport種別の旅程項目にはtransportIdだけを指定してください',
        );
      }
    case ItineraryEntryKind.lodging:
      if (!has(entry.lodgingId) || refCount != 1) {
        return const ValidationFailure(
          'lodging種別の旅程項目にはlodgingIdだけを指定してください',
        );
      }
    case ItineraryEntryKind.note:
      if (refCount != 0) {
        return const ValidationFailure('note種別の旅程項目には参照IDを指定できません');
      }
  }
  return null;
}

/// [ItineraryEntry] の不変条件をまとめて検証する。
Failure? validateItineraryEntry(ItineraryEntry entry) {
  final ref = validateItineraryEntryReference(entry);
  if (ref != null) return ref;
  final range = validateItineraryTimeRange(entry.startAt, entry.endAt);
  if (range != null) return range;
  final before = validateItineraryMinutes(
    entry.bufferBeforeMinutes,
    label: '到着前の余裕時間',
  );
  if (before != null) return before;
  final after = validateItineraryMinutes(
    entry.bufferAfterMinutes,
    label: '出発後の余裕時間',
  );
  if (after != null) return after;
  if (entry.timeZoneId != null) {
    final tz = validateItineraryTimeZoneId(entry.timeZoneId!);
    if (tz != null) return tz;
  }
  return null;
}

/// origin と destination が同じ旅程項目でないことを検証する（§6.2）。
Failure? validateItineraryLegEndpoints(ItineraryLeg leg) {
  if (leg.originEntryId == leg.destinationEntryId) {
    return const ValidationFailure('出発と到着に同じ旅程項目は指定できません');
  }
  return null;
}

/// [ItineraryLeg] の不変条件をまとめて検証する。
Failure? validateItineraryLeg(ItineraryLeg leg) {
  final endpoints = validateItineraryLegEndpoints(leg);
  if (endpoints != null) return endpoints;
  final range = validateItineraryTimeRange(leg.departureAt, leg.arrivalAt);
  if (range != null) return range;
  if (leg.durationMinutes != null) {
    final duration = validateItineraryMinutes(
      leg.durationMinutes!,
      label: '所要時間',
    );
    if (duration != null) return duration;
  }
  final distance = validateItineraryDistanceMeters(leg.distanceMeters);
  if (distance != null) return distance;
  final fare = validateItineraryFare(leg.fareAmountMinor, leg.fareCurrency);
  if (fare != null) return fare;
  final rights = validateItineraryRightsBasis(leg.valueOrigin, leg.rightsBasis);
  if (rights != null) return rights;
  if (leg.googleMapsUrl != null) {
    final f =
        validateItineraryUrl(leg.googleMapsUrl!, label: 'Google Maps URL');
    if (f != null) return f;
  }
  return null;
}
