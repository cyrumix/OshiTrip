import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';
import '../domain/profile.dart';

/// Supabase を使う [ProfileRepository] 実装（サーバー権威・RLS 準拠, D-233）。
///
/// プロフィールは複数ユーザーがまたぐため offline 同期（apply_mutation/outbox）に
/// 載せず、直接 `profiles` 表を読み書きする。可視範囲・本人限定編集はサーバーの
/// RLS（`can_view_profile` / `profiles_*_self`）が強制する。
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client, this._currentUserId);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  // profiles の主キーは `id`（= auth.users.id）。ドメインでは userId として扱う。
  static Profile _fromRow(Map<String, dynamic> r) => Profile(
        userId: r['id'] as String,
        displayName: (r['display_name'] as String?) ?? '',
        avatarUrl: r['avatar_url'] as String?,
        bio: r['bio'] as String?,
        favoriteName: r['favorite_name'] as String?,
        acceptsFriendRequests: (r['accepts_friend_requests'] as bool?) ?? true,
        searchable: (r['searchable'] as bool?) ?? false,
        friendCode: (r['friend_code'] as String?) ?? '',
        createdAt: _parseTime(r['created_at']),
        updatedAt: _parseTime(r['updated_at']),
      );

  static DateTime _parseTime(Object? v) =>
      v is String ? DateTime.parse(v).toUtc() : DateTime.now().toUtc();

  @override
  Future<Result<Profile?>> fetchMyProfile() async {
    final uid = _currentUserId();
    if (uid == null) return const Err(AuthFailure(message: 'ログインが必要です'));
    return _guard(() async {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle()
          .withRemoteTimeout();
      return row == null ? null : _fromRow(row);
    });
  }

  @override
  Future<Result<Profile>> upsertMyProfile({
    required String displayName,
    String? bio,
    String? favoriteName,
    required bool acceptsFriendRequests,
    required bool searchable,
  }) async {
    final uid = _currentUserId();
    if (uid == null) return const Err(AuthFailure(message: 'ログインが必要です'));
    final invariant = profileInvariantError(
      displayName: displayName,
      bio: bio,
      favoriteName: favoriteName,
    );
    if (invariant != null) return Err(ValidationFailure(invariant));
    return _guard(() async {
      final row = await _client
          .from('profiles')
          .upsert({
            'id': uid,
            'display_name': displayName.trim(),
            'bio': bio,
            'favorite_name': favoriteName,
            'accepts_friend_requests': acceptsFriendRequests,
            'searchable': searchable,
          })
          .select()
          .single()
          .withRemoteTimeout();
      return _fromRow(row);
    });
  }

  @override
  Future<Result<Profile?>> fetchProfile(String userId) => _guard(() async {
        final row = await _client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle()
            .withRemoteTimeout();
        return row == null ? null : _fromRow(row);
      });

  @override
  Future<Result<Map<String, Profile>>> fetchProfiles(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return const Ok({});
    return _guard(() async {
      final rows = await _client
          .from('profiles')
          .select()
          .inFilter('id', userIds)
          .withRemoteTimeout();
      final map = <String, Profile>{};
      for (final r in rows) {
        final p = _fromRow(r);
        map[p.userId] = p;
      }
      return map;
    });
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on AuthException catch (e) {
      return Err(AuthFailure(message: e.message));
    } catch (e) {
      return Err(NetworkFailure(cause: e));
    }
  }
}

/// デモ・未ログイン向けの no-op 実装（Supabase 未接続時）。
class UnavailableProfileRepository implements ProfileRepository {
  const UnavailableProfileRepository();

  @override
  Future<Result<Profile?>> fetchMyProfile() async => const Ok(null);

  @override
  Future<Result<Profile>> upsertMyProfile({
    required String displayName,
    String? bio,
    String? favoriteName,
    required bool acceptsFriendRequests,
    required bool searchable,
  }) async =>
      const Err(UnavailableFailure());

  @override
  Future<Result<Profile?>> fetchProfile(String userId) async => const Ok(null);

  @override
  Future<Result<Map<String, Profile>>> fetchProfiles(
    List<String> userIds,
  ) async =>
      const Ok({});
}
