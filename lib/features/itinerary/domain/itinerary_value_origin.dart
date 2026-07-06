import 'package:freezed_annotation/freezed_annotation.dart';

/// 永続する値（スポットの名称・住所、移動区間の概算経路など）の出典・権利根拠
/// （itinerary-plan-spec.md §4.3/§12.2/§12.5、decisions D-178〜D-181）。
///
/// 共有再利用の可否は「保存・再利用の権利を説明できるか」で決まる。Google
/// Places / Routes のライブ応答は Place ID を除きこの分類に含めない（Google
/// コンテンツを API 呼び出しの代替となる恒久キャッシュへ昇格させない）。
/// MVPで手動入力された値はすべて [userProvided]。
enum ItineraryValueOrigin {
  /// ユーザー本人が独立して入力した値（MVPの既定）。
  @JsonValue('user_provided')
  userProvided,

  /// 施設・主催者などが提供した値。
  @JsonValue('facility_provided')
  facilityProvided,

  /// オープンデータ由来の値。
  @JsonValue('open_data')
  openData,

  /// 契約・書面許諾に基づく値。
  @JsonValue('licensed')
  licensed,
}

extension ItineraryValueOriginLabel on ItineraryValueOrigin {
  String get label => switch (this) {
        ItineraryValueOrigin.userProvided => 'ユーザー入力',
        ItineraryValueOrigin.facilityProvided => '施設提供',
        ItineraryValueOrigin.openData => 'オープンデータ',
        ItineraryValueOrigin.licensed => '契約データ',
      };
}
