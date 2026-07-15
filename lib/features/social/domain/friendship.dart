import '../../../core/error/result.dart';

/// フレンド関係の状態（追加要件 §2）。`none` は行が存在しない状態を表す
/// クライアント側の便宜値で、サーバーには保存しない。
enum FriendshipStatus { none, pending, accepted, rejected, blocked }

extension FriendshipStatusCode on FriendshipStatus {
  String? get code => switch (this) {
        FriendshipStatus.none => null,
        FriendshipStatus.pending => 'pending',
        FriendshipStatus.accepted => 'accepted',
        FriendshipStatus.rejected => 'rejected',
        FriendshipStatus.blocked => 'blocked',
      };
}

FriendshipStatus friendshipStatusFromCode(String? code) => switch (code) {
      'pending' => FriendshipStatus.pending,
      'accepted' => FriendshipStatus.accepted,
      'rejected' => FriendshipStatus.rejected,
      'blocked' => FriendshipStatus.blocked,
      _ => FriendshipStatus.none,
    };

/// 1件のフレンド関係（[requesterId] が [receiverId] へ申請）。
class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 自分から見た相手のユーザーID。
  String otherId(String selfId) =>
      requesterId == selfId ? receiverId : requesterId;

  /// 自分が受信者か（応答できるのは受信者だけ）。
  bool isReceiver(String selfId) => receiverId == selfId;
}

/// フレンド申請を送れるかの純粋判定（サーバー `send_friend_request` と一致）。
/// 問題があれば理由、無ければ null。
///
/// 無制限検索を禁止するため、相手が [targetSearchable] または
/// [sharesGenba]（同一現場の共有メンバー）のときだけ申請できる。相手が
/// 申請を受け付けていない（[targetAcceptsRequests] == false）／ブロック中は不可。
String? canSendFriendRequest({
  required String selfId,
  required String targetId,
  required bool targetSearchable,
  required bool targetAcceptsRequests,
  required bool sharesGenba,
  bool isBlocked = false,
}) {
  if (targetId.trim().isEmpty) {
    return '相手を指定してください';
  }
  if (targetId == selfId) {
    return '自分自身へは申請できません';
  }
  if (isBlocked) {
    return 'この相手には申請できません';
  }
  if (!targetAcceptsRequests) {
    return '相手はフレンド申請を受け付けていません';
  }
  if (!targetSearchable && !sharesGenba) {
    // 同じ現場に参加したことがない・検索許可もしていない相手には送れない。
    return '同じ現場に参加した相手か、検索を許可している相手にのみ申請できます';
  }
  return null;
}

/// 申請へ応答できるかの純粋判定（受信者かつ pending のときだけ）。
/// 問題があれば理由、無ければ null。
String? friendshipRespondError({
  required FriendshipStatus status,
  required bool isReceiver,
}) {
  if (!isReceiver) {
    return '申請を受け取った本人だけが応答できます';
  }
  if (status != FriendshipStatus.pending) {
    return '応答できる申請がありません';
  }
  return null;
}

/// フレンド機能のリポジトリ抽象（本人操作・状態機械はサーバー RPC で強制）。
///
/// 複数ユーザーをまたぐサーバー権威データのため offline 同期には載せない。
abstract interface class FriendRepository {
  /// 自分に関わるフレンド関係を取得する（当事者のみ閲覧, RLS）。
  Future<Result<List<Friendship>>> fetchFriendships();

  /// フレンド申請を送る。
  Future<Result<FriendshipStatus>> sendRequest(String receiverId);

  /// フレンドコードで申請を送る（コード完全一致で相手を特定する）。
  /// searchable=false の相手でもコードを知っていれば送れる（無制限検索はしない）。
  Future<Result<FriendshipStatus>> sendRequestByCode(String friendCode);

  /// 受信した申請へ応答する（承認/拒否）。
  Future<Result<void>> respond(String friendshipId, {required bool accept});

  /// フレンドを削除する。
  Future<Result<void>> removeFriend(String otherUserId);
}
