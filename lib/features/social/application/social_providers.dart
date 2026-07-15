import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/friend_repository_impl.dart';
import '../data/profile_repository_impl.dart';
import '../domain/friendship.dart';
import '../domain/profile.dart';

/// 現在の認証ユーザーID（未ログイン・デモは null）。
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null || user.isDemo) return null;
  return user.id;
});

/// プロフィールリポジトリ（Supabase 接続時は実装、未接続/デモは no-op）。
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (client == null || uid == null) {
    return const UnavailableProfileRepository();
  }
  return SupabaseProfileRepository(
    client,
    () => ref.read(currentUserIdProvider),
  );
});

/// フレンドリポジトリ（Supabase 接続時は実装、未接続/デモは no-op）。
final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (client == null || uid == null) {
    return const UnavailableFriendRepository();
  }
  return SupabaseFriendRepository(
    client,
    () => ref.read(currentUserIdProvider),
  );
});

/// 自分のプロフィール（未設定なら null）。編集保存後に invalidate して再取得する。
final myProfileProvider = FutureProvider<Profile?>((ref) async {
  final result = await ref.watch(profileRepositoryProvider).fetchMyProfile();
  return result.valueOrNull;
});

/// フレンド一覧の1件（相手プロフィール付き）。
class FriendEntry {
  const FriendEntry({
    required this.friendship,
    required this.otherId,
    this.profile,
  });
  final Friendship friendship;
  final String otherId;
  final Profile? profile;

  /// 表示名（プロフィール未取得時はフォールバック）。
  String get displayName => profile?.displayName ?? 'ユーザー';
}

/// フレンド画面の3区分（承認済み・送信中・受信中）。
class FriendsView {
  const FriendsView({
    this.friends = const [],
    this.outgoing = const [],
    this.incoming = const [],
  });

  final List<FriendEntry> friends; // accepted
  final List<FriendEntry> outgoing; // 自分が申請中（pending・requester=自分）
  final List<FriendEntry> incoming; // 受信した申請（pending・receiver=自分）

  bool get isEmpty => friends.isEmpty && outgoing.isEmpty && incoming.isEmpty;
}

/// 自分に関わるフレンド関係（生リスト）。フレンド画面・メンバー画面が共有する。
/// 変更後は invalidate して再取得する。
final myFriendshipsProvider = FutureProvider<List<Friendship>>((ref) async {
  final selfId = ref.watch(currentUserIdProvider);
  if (selfId == null) return const [];
  final result = await ref.watch(friendRepositoryProvider).fetchFriendships();
  return result.valueOrNull ?? const [];
});

/// 指定ユーザーとの現在のフレンド状態（一覧に無ければ none）。
FriendshipStatus friendStatusFor(
  List<Friendship> friendships,
  String selfId,
  String otherId,
) {
  for (final f in friendships) {
    if (f.otherId(selfId) == otherId) return f.status;
  }
  return FriendshipStatus.none;
}

/// フレンド関係＋相手プロフィールを取得し、3区分へ整理する。
final friendsViewProvider = FutureProvider<FriendsView>((ref) async {
  final selfId = ref.watch(currentUserIdProvider);
  if (selfId == null) return const FriendsView();

  final friendships = await ref.watch(myFriendshipsProvider.future);
  if (friendships.isEmpty) return const FriendsView();

  final otherIds = friendships.map((f) => f.otherId(selfId)).toSet().toList();
  final profilesResult =
      await ref.watch(profileRepositoryProvider).fetchProfiles(otherIds);
  final profiles = profilesResult.valueOrNull ?? const {};

  final friends = <FriendEntry>[];
  final outgoing = <FriendEntry>[];
  final incoming = <FriendEntry>[];
  for (final f in friendships) {
    final otherId = f.otherId(selfId);
    final entry = FriendEntry(
      friendship: f,
      otherId: otherId,
      profile: profiles[otherId],
    );
    switch (f.status) {
      case FriendshipStatus.accepted:
        friends.add(entry);
      case FriendshipStatus.pending:
        if (f.requesterId == selfId) {
          outgoing.add(entry);
        } else {
          incoming.add(entry);
        }
      case FriendshipStatus.none:
      case FriendshipStatus.rejected:
      case FriendshipStatus.blocked:
        break; // 一覧には出さない
    }
  }
  return FriendsView(friends: friends, outgoing: outgoing, incoming: incoming);
});
