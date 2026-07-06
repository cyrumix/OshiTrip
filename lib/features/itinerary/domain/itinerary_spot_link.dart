// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/time/date_only.dart';

part 'itinerary_spot_link.freezed.dart';
part 'itinerary_spot_link.g.dart';

/// スポットへ紐づける種別つきURLの種別（itinerary-plan-spec.md §4.5）。
enum ItinerarySpotLinkKind {
  @JsonValue('reference')
  reference,
  @JsonValue('reservation')
  reservation,
  @JsonValue('google_maps')
  googleMaps,
  @JsonValue('social')
  social,
  @JsonValue('ticket')
  ticket,
  @JsonValue('official')
  official,
  @JsonValue('other')
  other,
}

extension ItinerarySpotLinkKindLabel on ItinerarySpotLinkKind {
  String get label => switch (this) {
        ItinerarySpotLinkKind.reference => '参考URL',
        ItinerarySpotLinkKind.reservation => '予約URL',
        ItinerarySpotLinkKind.googleMaps => 'Google Maps URL',
        ItinerarySpotLinkKind.social => 'SNS投稿URL',
        ItinerarySpotLinkKind.ticket => 'チケットURL',
        ItinerarySpotLinkKind.official => '公式サイトURL',
        ItinerarySpotLinkKind.other => 'その他',
      };
}

/// スポットに複数保持できる種別つきURL（1フィールドへ詰め込まない, §4.5）。
@freezed
abstract class ItinerarySpotLink with _$ItinerarySpotLink {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory ItinerarySpotLink({
    required String id,
    required String spotId,
    required String ownerId,
    required ItinerarySpotLinkKind kind,
    required String url,
    String? label,
    @Default(0) int sortOrder,
    @UtcDateTimeConverter() required DateTime createdAt,
    @UtcDateTimeConverter() required DateTime updatedAt,
  }) = _ItinerarySpotLink;

  factory ItinerarySpotLink.fromJson(Map<String, dynamic> json) =>
      _$ItinerarySpotLinkFromJson(json);
}
