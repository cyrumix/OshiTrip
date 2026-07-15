import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';
import '../domain/genba_invite.dart';
import '../domain/share.dart';

/// Supabase を使う [GenbaInviteRepository] 実装（サーバー権威 RPC・RLS 準拠, D-236）。
///
/// 発行・無効化・参加は SECURITY DEFINER RPC が owner 限定・token 検証
/// （revoked/expired/max_uses）・重複参加防止を強制する。参加すると `genba_shares`
/// 行が作られる。
class SupabaseGenbaInviteRepository implements GenbaInviteRepository {
  SupabaseGenbaInviteRepository(this._client);

  final SupabaseClient _client;

  static GenbaInvite _fromRow(Map<String, dynamic> r) => GenbaInvite(
        id: r['id'] as String,
        genbaId: r['genba_id'] as String,
        ownerId: r['owner_id'] as String,
        token: r['token'] as String,
        defaultRole:
            shareRoleFromCode(r['default_role'] as String?) ?? ShareRole.viewer,
        expiresAt: _parseTimeOrNull(r['expires_at']),
        revokedAt: _parseTimeOrNull(r['revoked_at']),
        maxUses: (r['max_uses'] as num?)?.toInt(),
        usedCount: (r['used_count'] as num?)?.toInt() ?? 0,
        createdAt: _parseTime(r['created_at']),
        updatedAt: _parseTime(r['updated_at']),
      );

  static DateTime? _parseTimeOrNull(Object? v) =>
      v is String ? DateTime.parse(v).toUtc() : null;

  static DateTime _parseTime(Object? v) =>
      v is String ? DateTime.parse(v).toUtc() : DateTime.now().toUtc();

  @override
  Future<Result<List<GenbaInvite>>> fetchInvites(String genbaId) =>
      _guard(() async {
        final rows = await _client
            .from('genba_invites')
            .select()
            .eq('genba_id', genbaId)
            .order('created_at')
            .withRemoteTimeout();
        return rows.map(_fromRow).toList();
      });

  @override
  Future<Result<GenbaInvite>> createInvite(
    String genbaId, {
    ShareRole role = ShareRole.viewer,
    DateTime? expiresAt,
    int? maxUses,
  }) =>
      _guard(() async {
        final res = await _client.rpc<dynamic>(
          'create_genba_invite',
          params: {
            'p_genba': genbaId,
            'p_role': role == ShareRole.editor ? 'editor' : 'viewer',
            'p_expires': expiresAt?.toUtc().toIso8601String(),
            'p_max_uses': maxUses,
          },
        ).withRemoteTimeout();
        final j = res as Map<String, dynamic>;
        final now = DateTime.now().toUtc();
        return GenbaInvite(
          id: j['id'] as String,
          genbaId: genbaId,
          ownerId: '', // 発行者=自分。一覧再取得で owner_id は満たされる。
          token: j['token'] as String,
          defaultRole: shareRoleFromCode(j['default_role'] as String?) ?? role,
          expiresAt: _parseTimeOrNull(j['expires_at']),
          maxUses: (j['max_uses'] as num?)?.toInt(),
          createdAt: now,
          updatedAt: now,
        );
      });

  @override
  Future<Result<void>> revokeInvite(String inviteId) => _guard(() async {
        await _client.rpc<dynamic>(
          'revoke_genba_invite',
          params: {'p_id': inviteId},
        ).withRemoteTimeout();
      });

  @override
  Future<Result<InvitePreview>> previewByToken(String token) =>
      _guard(() async {
        final res = await _client.rpc<dynamic>(
          'get_invite_preview',
          params: {'p_token': token},
        ).withRemoteTimeout();
        final j = res as Map<String, dynamic>;
        return InvitePreview(
          valid: j['valid'] as bool? ?? false,
          reason: j['reason'] as String?,
          genbaId: j['genba_id'] as String? ?? '',
          artistName: j['artist_name'] as String?,
          title: j['title'] as String?,
          eventDate: _parseTimeOrNull(j['event_date']),
          defaultRole: shareRoleFromCode(j['default_role'] as String?) ??
              ShareRole.viewer,
          ownerDisplayName: j['owner_display_name'] as String?,
          ownerAvatarUrl: j['owner_avatar_url'] as String?,
          alreadyMember: j['already_member'] as bool? ?? false,
        );
      });

  @override
  Future<Result<InviteJoinStatus>> joinByToken(String token) =>
      _guard(() async {
        final res = await _client.rpc<dynamic>(
          'join_genba_via_invite',
          params: {'p_token': token},
        ).withRemoteTimeout();
        final status = res is Map ? res['status'] as String? : null;
        return inviteJoinStatusFromCode(status);
      });

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message));
    } on PostgrestException catch (e) {
      return Err(_mapRpcError(e.message));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }

  /// RPC が raise した token 検証エラーを利用者向け Failure へ変換する。
  static Failure _mapRpcError(String message) {
    final m = message.toLowerCase();
    for (final reason in const [
      'invite_not_found',
      'invite_revoked',
      'invite_expired',
      'invite_exhausted',
    ]) {
      if (m.contains(reason)) {
        return ValidationFailure(inviteReasonMessage(reason));
      }
    }
    if (m.contains('only the owner')) {
      return const PermissionFailure(message: 'この操作はオーナーのみ可能です');
    }
    return NetworkFailure(cause: message);
  }
}

/// デモ・未ログイン向けの no-op 実装（Supabase 未接続時）。
class UnavailableGenbaInviteRepository implements GenbaInviteRepository {
  const UnavailableGenbaInviteRepository();

  @override
  Future<Result<List<GenbaInvite>>> fetchInvites(String genbaId) async =>
      const Ok([]);

  @override
  Future<Result<GenbaInvite>> createInvite(
    String genbaId, {
    ShareRole role = ShareRole.viewer,
    DateTime? expiresAt,
    int? maxUses,
  }) async =>
      const Err(UnavailableFailure());

  @override
  Future<Result<void>> revokeInvite(String inviteId) async =>
      const Err(UnavailableFailure());

  @override
  Future<Result<InvitePreview>> previewByToken(String token) async =>
      const Err(UnavailableFailure());

  @override
  Future<Result<InviteJoinStatus>> joinByToken(String token) async =>
      const Err(UnavailableFailure());
}
