// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/images/image_upload_status.dart';
import '../../../core/time/date_only.dart';
import 'itinerary_value_origin.dart';

part 'itinerary_spot.freezed.dart';
part 'itinerary_spot.g.dart';

/// スポット情報の取得元（itinerary-plan-spec.md §4.1）。
///
/// [googlePlaces] は「Google 検索から選択された Place ID を保持する」ことを
/// 示すためだけの区分であり、名称・住所などの Google 応答内容を恒久保存する
/// 許可を意味しない。永続する名称・住所の権利根拠は [ItinerarySpot.dataOrigin]
/// で別途表す（D-178/D-179）。
enum ItinerarySpotSource {
  @JsonValue('manual')
  manual,
  @JsonValue('google_places')
  googlePlaces,
}

/// スポットのカテゴリ（§4.4）。Googleのplace typeとはマッピングテーブルで
/// 変換し、変換不能なら [other] とする（変換テーブル自体は後続Phaseで実装）。
enum ItinerarySpotCategory {
  @JsonValue('venue')
  venue,
  @JsonValue('sightseeing')
  sightseeing,
  @JsonValue('restaurant')
  restaurant,
  @JsonValue('cafe')
  cafe,
  @JsonValue('lodging')
  lodging,
  @JsonValue('station')
  station,
  @JsonValue('airport')
  airport,
  @JsonValue('shopping')
  shopping,
  @JsonValue('shrine_temple')
  shrineTemple,
  @JsonValue('museum')
  museum,
  @JsonValue('park')
  park,
  @JsonValue('photo_spot')
  photoSpot,
  @JsonValue('convenience')
  convenience,
  @JsonValue('other')
  other,
}

extension ItinerarySpotCategoryLabel on ItinerarySpotCategory {
  String get label => switch (this) {
        ItinerarySpotCategory.venue => 'ライブ・イベント会場',
        ItinerarySpotCategory.sightseeing => '観光地',
        ItinerarySpotCategory.restaurant => '飲食店',
        ItinerarySpotCategory.cafe => 'カフェ',
        ItinerarySpotCategory.lodging => 'ホテル・宿泊',
        ItinerarySpotCategory.station => '駅',
        ItinerarySpotCategory.airport => '空港',
        ItinerarySpotCategory.shopping => '買い物・グッズ',
        ItinerarySpotCategory.shrineTemple => '神社・寺院',
        ItinerarySpotCategory.museum => '美術館・博物館',
        ItinerarySpotCategory.park => '公園・屋外',
        ItinerarySpotCategory.photoSpot => '撮影スポット',
        ItinerarySpotCategory.convenience => 'コンビニ・補給',
        ItinerarySpotCategory.other => 'その他',
      };
}

/// 計画に登録するスポット（施設・訪問先）自体。訪問予定（[ItineraryEntry]）
/// とは分離し、同じスポットを別日・別時間に複数回予定できる（§2.5）。
///
/// 永続する名称・住所の出典は [dataOrigin]（既定は [ItineraryValueOrigin
/// .userProvided]）と [rightsBasis] で表す。MVPで永続保存できる Google 由来値は
/// [googlePlaceId]（照合キー）だけであり、名称・住所を Google 応答から自動転記
/// して恒久保存しない（D-178/D-179）。
///
/// [googlePlaceId] を除く Google 関連フィールド（[phoneNumber] / [websiteUrl] /
/// [openingHoursText] / [googleMapsUrl] / [googleFetchedAt] / [googlePhotoName]
/// / [googlePhotoAttribution] / 及び Google 由来の座標）は、**将来の契約変更に
/// 備えた予約領域**であり、MVPでは Google 応答の保存先に使わない（§12.2）。
/// Google のライブ応答は同一画面・同一操作中の一時DTO/状態として扱い、この
/// 永続 entity へ暗黙変換しない。手動入力された座標は [dataOrigin]=userProvided。
///
/// Phase 3 で Google Places を接続する際も、名称・住所・電話・営業時間・写真等を
/// Google 応答からこの entity へ**自動転記しない**。一時DTOから、ユーザーが確認・
/// 入力した値として [dataOrigin]=userProvided の entity へ**明示変換**する
/// （Place ID は照合キーとして保持可, D-178/D-179）。
@freezed
abstract class ItinerarySpot with _$ItinerarySpot {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory ItinerarySpot({
    required String id,
    required String planId,
    required String ownerId,
    @Default(ItinerarySpotSource.manual) ItinerarySpotSource source,

    /// 永続保存できる唯一の Google 識別子（重複候補の照合キー。§4.3/§12.2）。
    String? googlePlaceId,

    /// 施設名（必須、前後空白除去・空文字不可は入力側/バリデーションで保証）。
    required String name,
    required ItinerarySpotCategory category,

    /// 住所（任意、センシティブ情報として扱う。§4.2）。
    String? address,

    /// 永続する名称・住所の出典・権利根拠（既定はユーザー入力, §12.2）。
    @Default(ItineraryValueOrigin.userProvided) ItineraryValueOrigin dataOrigin,
    String? rightsBasis,

    /// 緯度・経度は両方揃ったときだけ座標として有効（§4.2）。手動入力のみ。
    double? latitude,
    double? longitude,

    // ---- 予約領域（MVPでは Google 応答の保存に使わない, §12.2）----------------
    String? phoneNumber,
    String? websiteUrl,
    String? openingHoursText,
    String? googleMapsUrl,
    @NullableUtcDateTimeConverter() DateTime? googleFetchedAt,
    String? googlePhotoName,
    String? googlePhotoAttribution,

    /// ユーザー所有画像（既存 ImageStore/Storage 契約と同じ形。§7.1）。
    String? userImageLocalPath,
    String? userImageStoragePath,
    @Default(ImageUploadStatus.localOnly)
    ImageUploadStatus userImageUploadStatus,
    String? userImageAltText,
    String? memo,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _ItinerarySpot;

  factory ItinerarySpot.fromJson(Map<String, dynamic> json) =>
      _$ItinerarySpotFromJson(json);
}
