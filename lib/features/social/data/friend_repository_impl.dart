import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/network/network_timeout.dart';
import '../domain/friendship.dart';

/// Supabase を使う [FriendRepository] 実装（サーバー権威 RPC・RLS 準拠, D-233）。
///
/// 状態遷移（申請・承認・拒否・削除）は SECURITY DEFINER RPC が本人性・許可条件
/// （searchable または同一現場メンバー）・状態機械を強制する。一覧は RLS で
/// 当事者の行だけが返る。
class SupabaseFriendRepository implements FriendRepository {
  SupabaseFriendRepository(this._client, this._currentUserId);

  final SupabaseClient _client;
  final String? Function() _currentUserId;

  static Friendship _fromRow(Map<String, dynamic> r) => Friendship(
        id: r['id'] as String,
        requesterId: r['requester_id'] as String,
        receiverId: r['receiver_id'] as String,
        status: friendshipStatusFromCode(r['status'] as String?),
        createdAt: _parseTime(r['created_at']),
        updatedAt: _parseTime(r['updated_at']),
      );

  static DateTime _parseTime(Object? v) =>
      v is String ? DateTime.parse(v).toUtc() : DateTime.now().toUtc();

  @override
  Future<Result<List<Friendship>>> fetchFriendships() async {
    final uid = _currentUserId();
    if (uid == null) return const Err(AuthFailure(message: 'ログインが必要です'));
    return _guard(() async {
      final rows = await _client
          .from('friendships')
          .select()
          .order('updated_at')
          .withRemoteTimeout();
      return rows.map(_fromRow).toList();
    });
  }

  @override
  Future<Result<FriendshipStatus>> sendRequest(String receiverId) => _guard(
        () async {
          final res = await _client.rpc<dynamic>(
            'send_friend_request',
            params: {'p_receiver': receiverId},
          ).withRemoteTimeout();
          final status = res is Map ? res['status'] as String? : null;
          return friendshipStatusFromCode(status);
        },
      );

  @override
  Future<Result<FriendshipStatus>> sendRequestByCode(String friendCode) =>
      _guard(() async {
        final res = await _client.rpc<dynamic>(
          'send_friend_request_by_code',
          params: {'p_friend_code': friendCode},
        ).withRemoteTimeout();
        final status = res is Map ? res['status'] as String? : null;
        return friendshipStatusFromCode(status);
      });

  @override
  Future<Result<void>> respond(String friendshipId, {required bool accept}) =>
      _guard(() async {
        await _client.rpc<dynamic>(
          'respond_friend_request',
          params: {'p_id': friendshipId, 'p_accept': accept},
        ).withRemoteTimeout();
      });

  @override
  Future<Result<void>> removeFriend(String otherUserId) => _guard(() async {
        await _client.rpc<dynamic>(
          'remove_friend',
          params: {'p_other': otherUserId},
        ).withRemoteTimeout();
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

  /// RPC が raise した英語メッセージを利用者向け Failure へ変換する。
  static Failure _mapRpcError(String message) {
    final m = message.toLowerCase();
    if (m.contains('not accepting')) {
      return const ValidationFailure('相手はフレンド申請を受け付けていません');
    }
    if (m.contains('not allowed to request')) {
      return const ValidationFailure(
        '同じ現場に参加した相手か、検索を許可している相手にのみ申請できます',
      );
    }
    if (m.contains('blocked')) {
      return const PermissionFailure(message: 'この相手には申請できません');
    }
    if (m.contains('no pending request')) {
      return const ValidationFailure('応答できる申請がありません');
    }
    if (m.contains('yourself')) {
      return const ValidationFailure('自分自身へは申請できません');
    }
    if (m.contains('friend code not found')) {
      return const ValidationFailure('そのフレンドコードのユーザーが見つかりません');
    }
    if (m.contains('friend code is required')) {
      return const ValidationFailure('フレンドコードを入力してください');
    }
    return NetworkFailure(cause: message);
  }
}

/// デモ・未ログイン向けの no-op 実装（Supabase 未接続時）。
class UnavailableFriendRepository implements FriendRepository {
  const UnavailableFriendRepository();

  @override
  Future<Result<List<Friendship>>> fetchFriendships() async => const Ok([]);

  @override
  Future<Result<FriendshipStatus>> sendRequest(String receiverId) async =>
      const Err(UnavailableFailure());

  @override
  Future<Result<FriendshipStatus>> sendRequestByCode(String friendCode) async =>
      const Err(UnavailableFailure());

  @override
  Future<Result<void>> respond(
    String friendshipId, {
    required bool accept,
  }) async =>
      const Err(UnavailableFailure());

  @override
  Future<Result<void>> removeFriend(String otherUserId) async =>
      const Err(UnavailableFailure());
}
