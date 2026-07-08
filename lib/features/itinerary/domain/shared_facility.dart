import 'itinerary_value_origin.dart';

/// 共有施設のモデレーション状態（itinerary-plan-spec §4.3・Supabase 0022）。
/// owner 別下書き（[draft]）→提出（[pending]）→モデレーションで承認（[approved]）
/// または却下（[rejected]）。承認（共有）は service role のみが行う。
enum FacilityModerationStatus { draft, pending, approved, rejected }

extension FacilityModerationStatusCode on FacilityModerationStatus {
  String get code => switch (this) {
        FacilityModerationStatus.draft => 'draft',
        FacilityModerationStatus.pending => 'pending',
        FacilityModerationStatus.approved => 'approved',
        FacilityModerationStatus.rejected => 'rejected',
      };

  /// 共有として公開されているか。
  bool get isShared => this == FacilityModerationStatus.approved;
}

FacilityModerationStatus facilityModerationStatusFromCode(String? code) =>
    switch (code) {
      'pending' => FacilityModerationStatus.pending,
      'approved' => FacilityModerationStatus.approved,
      'rejected' => FacilityModerationStatus.rejected,
      _ => FacilityModerationStatus.draft,
    };

/// 共有施設の登録・昇格の**不変条件**（§4.3/§6・Supabase 0022 と一致する純粋関数）。
/// DB に依存しないフィールド検証を行い、問題があれば理由、無ければ null を返す。
///
/// - `data_origin` は [ItineraryValueOrigin]（user_provided/facility_provided/
///   open_data/licensed の4種）に**型で限定**される。Google 応答をそのまま出典に
///   した登録は表現できない（'google' 値が存在しない = ADR-0010 §7 の「Google 由来
///   共有登録拒否」を型で担保）。
/// - 承認（共有）へ昇格するには `rights_basis`（権利根拠の説明）が必須。
/// - Google Place ID は重複候補の照合キーとしては保持してよい（名称・住所の権利
///   根拠にはしない）。ここでは Place ID の有無は制約しない。
String? sharedFacilityInvariantError({
  required ItineraryValueOrigin dataOrigin,
  required String? rightsBasis,
  required FacilityModerationStatus status,
}) {
  if (status == FacilityModerationStatus.approved) {
    final basis = rightsBasis?.trim() ?? '';
    if (basis.isEmpty) {
      return '共有（承認）には権利根拠(rights_basis)が必要です';
    }
  }
  return null;
}
