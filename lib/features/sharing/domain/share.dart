import '../../../core/error/result.dart';

/// 共有権限（§7.8 / ADR-0008）。
///
/// 今回は「境界と土台」のみ: 型・Repository抽象・サーバースキーマ
/// （genba_shares + RLS）まで。招待UI・Realtime共同編集・項目単位の
/// 共有設定UIは docs/follow-up-work.md 参照。
enum ShareRole { owner, editor, viewer }

/// 項目単位の共有可否（チケット画像・予約番号・住所・感想）。
class FieldGrants {
  const FieldGrants({
    this.ticketImage = false,
    this.reservationNumber = false,
    this.address = false,
    this.impression = false,
  });

  final bool ticketImage;
  final bool reservationNumber;
  final bool address;
  final bool impression;
}

class GenbaShare {
  const GenbaShare({
    required this.genbaId,
    required this.granteeId,
    required this.role,
    this.fieldGrants = const FieldGrants(),
  });

  final String genbaId;
  final String granteeId;
  final ShareRole role;
  final FieldGrants fieldGrants;
}

abstract interface class ShareRepository {
  Future<Result<List<GenbaShare>>> listShares(String genbaId);
  Future<Result<void>> upsertShare(GenbaShare share);
  Future<Result<void>> removeShare(String genbaId, String granteeId);
}
