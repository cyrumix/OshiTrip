import '../../../core/error/result.dart';

/// 共有権限（§7.8 / ADR-0008）。
///
/// Phase 5 前提基盤（保守的スライス）: 共有**データ基盤**（genba_shares 表・型・
/// Repository・owner 管理 RLS・同期）まで。grantee による実 read/write のロール別
/// RLS・項目マスキング・Storage 共有・editor write-through・Realtime 共同編集・
/// 招待/項目共有設定 UI は次増分（decisions.md D-226・docs/follow-up-work.md）。
///
/// owner は現場の所有者（`genbas.owner_id`）で暗黙。共有行の [ShareRole] は
/// grantee の権限で editor / viewer のいずれか。
enum ShareRole { owner, editor, viewer }

extension ShareRoleCode on ShareRole {
  String get code => switch (this) {
        ShareRole.owner => 'owner',
        ShareRole.editor => 'editor',
        ShareRole.viewer => 'viewer',
      };
}

/// 共有行として保存できるのは grantee 権限（editor/viewer）のみ。owner は現場
/// 所有者として暗黙のため share 行にはしない（サーバー CHECK と一致）。
ShareRole? shareRoleFromCode(String? code) => switch (code) {
      'editor' => ShareRole.editor,
      'viewer' => ShareRole.viewer,
      _ => null,
    };

/// 項目単位の共有可否（チケット画像・予約番号・住所・感想, §7.8）。
/// 安全側＝既定 false。
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

  FieldGrants copyWith({
    bool? ticketImage,
    bool? reservationNumber,
    bool? address,
    bool? impression,
  }) =>
      FieldGrants(
        ticketImage: ticketImage ?? this.ticketImage,
        reservationNumber: reservationNumber ?? this.reservationNumber,
        address: address ?? this.address,
        impression: impression ?? this.impression,
      );

  @override
  bool operator ==(Object other) =>
      other is FieldGrants &&
      other.ticketImage == ticketImage &&
      other.reservationNumber == reservationNumber &&
      other.address == address &&
      other.impression == impression;

  @override
  int get hashCode =>
      Object.hash(ticketImage, reservationNumber, address, impression);
}

/// 1件の共有（owner が現場 [genbaId] を [granteeId] へ [role] で共有する）。
///
/// [ownerId] は共有元（現場所有者）。[version] はサーバーCASの版
/// （既存の apply_mutation 版CASに乗るため同期・競合解決を再利用できる）。
class GenbaShare {
  const GenbaShare({
    required this.id,
    required this.ownerId,
    required this.genbaId,
    required this.granteeId,
    required this.role,
    this.fieldGrants = const FieldGrants(),
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String genbaId;
  final String granteeId;
  final ShareRole role;
  final FieldGrants fieldGrants;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  GenbaShare copyWith({
    ShareRole? role,
    FieldGrants? fieldGrants,
    int? version,
    DateTime? updatedAt,
  }) =>
      GenbaShare(
        id: id,
        ownerId: ownerId,
        genbaId: genbaId,
        granteeId: granteeId,
        role: role ?? this.role,
        fieldGrants: fieldGrants ?? this.fieldGrants,
        version: version ?? this.version,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// 共有行の**不変条件**（サーバーの CHECK / 子owner トリガと一致する純粋関数）。
/// 問題があれば理由、無ければ null。
///
/// - grantee ≠ owner（自分自身へは共有しない, サーバー `genba_shares_not_self`）。
/// - role は editor / viewer（owner は share 行にしない, サーバー CHECK）。
///
/// 「他人の現場を共有できない」（owner が現場所有者であること）はローカルの親owner
/// 検証（`parentBelongsToOwner`）とサーバーの子owner トリガで担保する（ここでは
/// フィールド単体の検証に留める）。
String? shareInvariantError({
  required String ownerId,
  required String granteeId,
  required ShareRole role,
}) {
  if (granteeId.trim().isEmpty) {
    return '共有先ユーザーを指定してください';
  }
  if (granteeId == ownerId) {
    return '自分自身へは共有できません';
  }
  if (role != ShareRole.editor && role != ShareRole.viewer) {
    return '共有権限は editor か viewer を指定してください';
  }
  return null;
}

/// 現場共有のリポジトリ抽象（owner 側の共有管理 + owner スコープ同期）。
///
/// owner が自分の現場の共有を作成・変更・削除する。grantee 側の「共有された現場を
/// 読む」導線はロール別 read RLS を伴う次増分。
abstract interface class ShareRepository {
  /// 指定現場の共有一覧を現在owner限定で監視する。
  Stream<List<GenbaShare>> watchShares(String genbaId);

  /// 共有を作成・更新する（親現場を owner が所有していることを検証）。
  Future<Result<void>> upsertShare(GenbaShare share);

  /// 共有を解除する。
  Future<Result<void>> removeShare(String shareId);

  /// リモートの共有をローカルへ取り込む。デモ・未ログインでは何もしない。
  Future<Result<void>> refreshFromRemote({bool Function()? isStale});

  /// 競合解決「サーバーを採用」用。所有しないテーブルは失敗を返す。
  Future<Result<void>> adoptServerEntity(String entityTable, String entityId);
}
