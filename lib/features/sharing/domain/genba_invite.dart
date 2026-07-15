import '../../../core/error/result.dart';
import 'share.dart';

/// 招待URLの標準ホスト（Deep Link 最終形 `https://oshitrip.app/invite/{token}`）。
const String kInviteUrlBase = 'https://oshitrip.app/invite/';

/// 現場ごとの招待URL（追加要件 §3）。owner のみ発行・無効化でき、参加すると
/// その現場の共有メンバー（`genba_shares`）に [defaultRole] で追加される。
class GenbaInvite {
  const GenbaInvite({
    required this.id,
    required this.genbaId,
    required this.ownerId,
    required this.token,
    this.defaultRole = ShareRole.viewer,
    this.expiresAt,
    this.revokedAt,
    this.maxUses,
    this.usedCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String genbaId;
  final String ownerId;
  final String token;

  /// 参加後の初期権限（既定 viewer, §3）。
  final ShareRole defaultRole;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final int? maxUses;
  final int usedCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 共有可能な招待URL（LINE/DM で送る）。
  String get url => inviteUrlFor(token);

  /// この招待が現時点で有効か（[now] 基準）。
  bool isValidAt(DateTime now) =>
      inviteValidityError(
        revokedAt: revokedAt,
        expiresAt: expiresAt,
        maxUses: maxUses,
        usedCount: usedCount,
        now: now,
      ) ==
      null;
}

/// 招待の有効性理由（無効なら理由コード、有効なら null）。
/// サーバー `get_invite_preview` / `join_genba_via_invite` の判定順と一致する。
///
/// 判定順: 無効化 → 期限切れ → 使用上限超過。
String? inviteValidityError({
  required DateTime? revokedAt,
  required DateTime? expiresAt,
  required int? maxUses,
  required int usedCount,
  required DateTime now,
}) {
  if (revokedAt != null) return 'invite_revoked';
  if (expiresAt != null && expiresAt.isBefore(now)) return 'invite_expired';
  if (maxUses != null && usedCount >= maxUses) return 'invite_exhausted';
  return null;
}

/// 無効理由コードを利用者向け文言へ変換する。
String inviteReasonMessage(String? reason) => switch (reason) {
      'invite_revoked' => 'この招待リンクは無効化されています',
      'invite_expired' => 'この招待リンクは有効期限が切れています',
      'invite_exhausted' => 'この招待リンクは利用上限に達しています',
      'invite_not_found' => '招待リンクが見つかりませんでした',
      _ => '招待リンクを利用できませんでした',
    };

/// トークンから招待URLを組み立てる。
String inviteUrlFor(String token) => '$kInviteUrlBase$token';

/// 招待URL（またはトークン文字列）からトークンを取り出す。
///
/// `https://oshitrip.app/invite/{token}` の他、token をそのまま貼り付けた場合も
/// 受け付ける（初回実装の代替導線: token 入力/貼り付け参加, §8）。取り出せない
/// ときは null。
String? inviteTokenFromUrl(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
    final segments = uri.pathSegments;
    final idx = segments.indexOf('invite');
    if (idx >= 0 && idx + 1 < segments.length) {
      final token = segments[idx + 1].trim();
      return token.isEmpty ? null : token;
    }
    // /invite が無い URL はトークンとして扱わない（誤爆防止）。
    return null;
  }

  // URL でなければトークン直貼りとみなす（16進トークンのみ許容）。
  final tokenPattern = RegExp(r'^[0-9a-fA-F]{16,}$');
  return tokenPattern.hasMatch(trimmed) ? trimmed : null;
}

/// 招待参加の結果種別（サーバー `join_genba_via_invite` の status）。
enum InviteJoinStatus { joined, alreadyMember, owner }

InviteJoinStatus inviteJoinStatusFromCode(String? code) => switch (code) {
      'joined' => InviteJoinStatus.joined,
      'already_member' => InviteJoinStatus.alreadyMember,
      'owner' => InviteJoinStatus.owner,
      _ => InviteJoinStatus.alreadyMember,
    };

/// 参加確認画面のプレビュー（現場名・公演名・日付・発行者・付与権限・有効性）。
class InvitePreview {
  const InvitePreview({
    required this.valid,
    this.reason,
    required this.genbaId,
    this.artistName,
    this.title,
    this.eventDate,
    this.defaultRole = ShareRole.viewer,
    this.ownerDisplayName,
    this.ownerAvatarUrl,
    this.alreadyMember = false,
  });

  final bool valid;
  final String? reason;
  final String genbaId;
  final String? artistName;
  final String? title;
  final DateTime? eventDate;
  final ShareRole defaultRole;
  final String? ownerDisplayName;
  final String? ownerAvatarUrl;
  final bool alreadyMember;
}

/// 招待URLのリポジトリ抽象（owner 発行/無効化・token 参加）。
///
/// 複数ユーザーをまたぐサーバー権威データのため offline 同期には載せない。
abstract interface class GenbaInviteRepository {
  /// 指定現場の招待一覧を owner 限定で取得する。
  Future<Result<List<GenbaInvite>>> fetchInvites(String genbaId);

  /// 招待URLを発行する（owner のみ）。
  Future<Result<GenbaInvite>> createInvite(
    String genbaId, {
    ShareRole role = ShareRole.viewer,
    DateTime? expiresAt,
    int? maxUses,
  });

  /// 招待URLを無効化する（owner のみ）。
  Future<Result<void>> revokeInvite(String inviteId);

  /// token から参加プレビューを取得する（参加はしない）。
  Future<Result<InvitePreview>> previewByToken(String token);

  /// token で現場へ参加する（参加済み/owner は重複追加しない）。
  Future<Result<InviteJoinStatus>> joinByToken(String token);
}
