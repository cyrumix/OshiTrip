import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_timeout.dart';
import '../../../core/providers.dart';
import '../../genba/application/genba_providers.dart';
import '../../sharing/data/genba_invite_repository_impl.dart';
import '../../sharing/data/shared_genba_fetcher.dart';
import '../../sharing/data/shared_mutation_client.dart';
import '../../sharing/domain/genba_invite.dart';
import '../../sharing/domain/genba_permission.dart';
import '../../sharing/domain/share.dart';
import '../../sharing/domain/shared_genba_summary.dart';
import '../domain/friendship.dart';
import '../domain/profile.dart';
import 'social_providers.dart';

/// 指定現場の共有一覧（owner スコープ・genba_shares）。
final genbaSharesStreamProvider =
    StreamProvider.family<List<GenbaShare>, String>(
  (ref, genbaId) =>
      ref.watch(genbaSharesRepositoryProvider).watchShares(genbaId),
);

/// 共有メンバー1件（共有行＋相手プロフィール＋自分とのフレンド状態）。
class MemberEntry {
  const MemberEntry({
    required this.share,
    this.profile,
    this.friendStatus = FriendshipStatus.none,
  });

  final GenbaShare share;
  final Profile? profile;
  final FriendshipStatus friendStatus;

  String get displayName => profile?.displayName ?? 'ユーザー';
  String get userId => share.granteeId;
}

/// フレンドから追加できる候補（既にメンバーの相手は除外）。
class AddableFriend {
  const AddableFriend({required this.userId, this.profile});
  final String userId;
  final Profile? profile;
  String get displayName => profile?.displayName ?? 'ユーザー';
}

/// 現場メンバー画面の表示モデル。
class MembersView {
  const MembersView({
    required this.genbaId,
    required this.amOwner,
    this.isMember = false,
    this.selfRole = ShareRole.viewer,
    this.ownerProfile,
    this.members = const [],
    this.addableFriends = const [],
  });

  final String genbaId;

  /// 自分がこの現場のオーナーか（メンバー管理はオーナーのみ）。
  final bool amOwner;

  /// 自分が共有メンバー（editor/viewer）か。非オーナーでも一覧は閲覧できる（§4）。
  final bool isMember;

  /// 自分の権限。
  final ShareRole selfRole;

  final Profile? ownerProfile;
  final List<MemberEntry> members;
  final List<AddableFriend> addableFriends;
}

/// 現場のメンバー・共有ビュー。
///
/// - **オーナー**: ローカル owner スコープの共有一覧＋フレンド追加候補（管理可）。
/// - **共有メンバー（非オーナー・§4）**: サーバー権威で genba_shares を取得し、メンバー
///   一覧と自分の権限を**閲覧のみ**表示（管理不可）。同一現場メンバーへフレンド申請可。
/// - **権限なし**: amOwner=false・isMember=false（アクセス不可の案内）。
final genbaMembersProvider =
    FutureProvider.family<MembersView, String>((ref, genbaId) async {
  final selfId = ref.watch(currentUserIdProvider);
  if (selfId == null) {
    return MembersView(genbaId: genbaId, amOwner: false);
  }
  final localAgg = await ref.watch(genbaByIdProvider(genbaId).future);
  final isOwner = localAgg != null && localAgg.genba.ownerId == selfId;

  final friendships = await ref.watch(myFriendshipsProvider.future);
  final profilesRepo = ref.watch(profileRepositoryProvider);

  if (isOwner) {
    final shares = await ref.watch(genbaSharesStreamProvider(genbaId).future);
    final friendsView = await ref.watch(friendsViewProvider.future);
    final memberIds = shares.map((s) => s.granteeId).toSet();
    final wantedIds = <String>{
      ...memberIds,
      localAgg.genba.ownerId,
      ...friendsView.friends.map((f) => f.otherId),
    }.toList();
    final profiles =
        (await profilesRepo.fetchProfiles(wantedIds)).valueOrNull ?? const {};
    final members = [
      for (final s in shares)
        MemberEntry(
          share: s,
          profile: profiles[s.granteeId],
          friendStatus: friendStatusFor(friendships, selfId, s.granteeId),
        ),
    ];
    final addable = [
      for (final f in friendsView.friends)
        if (!memberIds.contains(f.otherId) &&
            f.otherId != localAgg.genba.ownerId)
          AddableFriend(userId: f.otherId, profile: profiles[f.otherId]),
    ];
    return MembersView(
      genbaId: genbaId,
      amOwner: true,
      isMember: true,
      selfRole: ShareRole.owner,
      ownerProfile: profiles[localAgg.genba.ownerId],
      members: members,
      addableFriends: addable,
    );
  }

  // 非オーナー: 共有メンバーなら genba_shares をサーバーから読んで閲覧表示（§4）。
  final roles = await ref.watch(myGenbaRolesProvider.future);
  final myRole = roles[genbaId];
  final client = ref.watch(supabaseClientProvider);
  if (myRole == null || client == null) {
    return MembersView(genbaId: genbaId, amOwner: false);
  }
  try {
    final rows = await client
        .from('genba_shares')
        .select('owner_id, grantee_id, role')
        .eq('genba_id', genbaId)
        .withRemoteTimeout();
    if (rows.isEmpty) {
      return MembersView(
        genbaId: genbaId,
        amOwner: false,
        isMember: true,
        selfRole: myRole,
      );
    }
    final ownerId = rows.first['owner_id'] as String?;
    final wantedIds = <String>{
      for (final r in rows) r['grantee_id'] as String,
      if (ownerId != null) ownerId,
    }.toList();
    final profiles =
        (await profilesRepo.fetchProfiles(wantedIds)).valueOrNull ?? const {};
    final now = ref.read(clockProvider).now().toUtc();
    final members = [
      for (final r in rows)
        MemberEntry(
          share: GenbaShare(
            id: '',
            ownerId: ownerId ?? '',
            genbaId: genbaId,
            granteeId: r['grantee_id'] as String,
            role: shareRoleFromCode(r['role'] as String?) ?? ShareRole.viewer,
            createdAt: now,
            updatedAt: now,
          ),
          profile: profiles[r['grantee_id']],
          friendStatus:
              friendStatusFor(friendships, selfId, r['grantee_id'] as String),
        ),
    ];
    return MembersView(
      genbaId: genbaId,
      amOwner: false,
      isMember: true,
      selfRole: myRole,
      ownerProfile: ownerId == null ? null : profiles[ownerId],
      members: members,
    );
  } catch (_) {
    return MembersView(
      genbaId: genbaId,
      amOwner: false,
      isMember: true,
      selfRole: myRole,
    );
  }
});

/// 招待URLのリポジトリ（Supabase 接続時は実装、未接続/デモは no-op, D-236）。
final genbaInviteRepositoryProvider = Provider<GenbaInviteRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (client == null || uid == null) {
    return const UnavailableGenbaInviteRepository();
  }
  return SupabaseGenbaInviteRepository(client);
});

/// 指定現場の招待一覧（owner 限定）。発行/無効化後に invalidate して再取得する。
final genbaInvitesProvider =
    FutureProvider.family<List<GenbaInvite>, String>((ref, genbaId) async {
  final result =
      await ref.watch(genbaInviteRepositoryProvider).fetchInvites(genbaId);
  return result.valueOrNull ?? const [];
});

/// token の参加プレビュー（現場名・公演名・日付・発行者・権限・有効性）。
/// 取得できない（通信不能・未接続）ときは null。
final invitePreviewProvider =
    FutureProvider.family<InvitePreview?, String>((ref, token) async {
  final result =
      await ref.watch(genbaInviteRepositoryProvider).previewByToken(token);
  return result.valueOrNull;
});

/// 自分が共有メンバー（grantee）になっている現場のロール一覧（genbaId → ShareRole）。
///
/// サーバー権威（`genba_shares` を grantee_id=自分で取得）。共有現場の「共有」バッジ・
/// 権限表示・viewer/editor のUI出し分け（`genbaPermissionFor`）の基礎データ。
/// 未接続/デモは空。共有現場本体・子データの実表示/編集の配線は次増分（D-238）。
final myGenbaRolesProvider =
    FutureProvider<Map<String, ShareRole>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (client == null || uid == null) return const {};
  try {
    final rows = await client
        .from('genba_shares')
        .select('genba_id, role')
        .eq('grantee_id', uid)
        .withRemoteTimeout();
    return {
      for (final r in rows)
        r['genba_id'] as String:
            shareRoleFromCode(r['role'] as String?) ?? ShareRole.viewer,
    };
  } catch (_) {
    return const {};
  }
});

/// 指定現場に対する自分の権限（owner 判定＋共有ロール）。UIの出し分けに使う。
final genbaPermissionProvider =
    FutureProvider.family<GenbaPermission, String>((ref, genbaId) async {
  final selfId = ref.watch(currentUserIdProvider);
  final aggregate = await ref.watch(genbaByIdProvider(genbaId).future);
  final isOwner = selfId != null && aggregate?.genba.ownerId == selfId;
  final roles = await ref.watch(myGenbaRolesProvider.future);
  return genbaPermissionFor(isOwner: isOwner, memberRole: roles[genbaId]);
});

/// 自分が共有された現場のサマリ一覧（ホーム/現場一覧の「共有された現場」節・§1）。
///
/// サーバー権威（`genba_shares` を grantee_id=自分で取得し、埋め込みで `genbas` を
/// 結合）。共有現場本体はローカル owner スコープに入らないため一覧はこのサマリで
/// 表示する。詳細/編集の取得は次増分（D-239）。未接続/デモは空。
final sharedGenbaSummariesProvider =
    FutureProvider<List<SharedGenbaSummary>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (client == null || uid == null) return const [];
  try {
    final rows = await client
        .from('genba_shares')
        .select('role, genbas(id, title, artist_name, event_date)')
        .eq('grantee_id', uid)
        .withRemoteTimeout();
    final result = <SharedGenbaSummary>[];
    for (final r in rows) {
      final g = r['genbas'];
      if (g is! Map) continue;
      final id = g['id'] as String?;
      if (id == null) continue;
      final date = g['event_date'];
      result.add(
        SharedGenbaSummary(
          genbaId: id,
          title: (g['title'] as String?) ?? '現場',
          artistName: g['artist_name'] as String?,
          eventDate: date is String ? DateTime.tryParse(date) : null,
          role: shareRoleFromCode(r['role'] as String?) ?? ShareRole.viewer,
        ),
      );
    }
    return result;
  } catch (_) {
    return const [];
  }
});

/// 共有現場の取得境界（Supabase 接続時は実装、未接続/デモは no-op）。
final sharedGenbaFetcherProvider = Provider<SharedGenbaFetcher>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (client == null || uid == null) {
    return const UnavailableSharedGenbaFetcher();
  }
  return SupabaseSharedGenbaFetcher(client);
});

/// 共有現場の editor 書き込みクライアント（apply_shared_mutation RPC 経由）。
/// 未接続/デモは no-op。viewer の書き込み抑止は最終的にサーバー RPC が担う。
final sharedMutationClientProvider = Provider<SharedMutationClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final uid = ref.watch(currentUserIdProvider);
  if (client == null || uid == null) {
    return const UnavailableSharedMutationClient();
  }
  return SupabaseSharedMutationClient(client);
});

/// 共有現場詳細（閲覧用データ ＋ 自分の権限）。
///
/// 権限が無い（未共有・共有解除後）と `permission.canView == false`・`data` は
/// null になり、詳細を開いても表示しない（§5/§7）。`myGenbaRolesProvider` を
/// 再取得すれば共有解除が反映される。
class SharedGenbaDetail {
  const SharedGenbaDetail({required this.data, required this.permission});
  final SharedGenbaData? data;
  final GenbaPermission permission;
}

final sharedGenbaDetailProvider =
    FutureProvider.family<SharedGenbaDetail, String>((ref, genbaId) async {
  final roles = await ref.watch(myGenbaRolesProvider.future);
  final permission =
      genbaPermissionFor(isOwner: false, memberRole: roles[genbaId]);
  if (!permission.canView) {
    return SharedGenbaDetail(data: null, permission: permission);
  }
  final result = await ref.watch(sharedGenbaFetcherProvider).fetch(genbaId);
  return SharedGenbaDetail(data: result.valueOrNull, permission: permission);
});
