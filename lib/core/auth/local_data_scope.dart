/// 認証主体ごとのローカルデータ境界（C-01 対策, ADR-0008 のクライアント側適用）。
///
/// owner_id が確定するまで、いかなるユーザーデータの watch/read/write/sync も
/// 開始しない。未認証・認証復元中は前ユーザーのローカルキャッシュへ到達できない。
///
/// [currentUserProvider]（認証状態ストリーム）から導出し、Repository/Outbox/
/// SyncEngine/下書きストアはすべてこの型を経由して owner を解決する。
sealed class LocalDataScope {
  const LocalDataScope();
}

/// 認証状態の復元が完了していない（起動直後・authStateChanges の初回値待ち）。
///
/// この間は前回起動時の値も含め、いかなるユーザーデータも表示しない。
class LocalDataScopeLoading extends LocalDataScope {
  const LocalDataScopeLoading();
}

/// 未認証（ログアウト済み・削除済みを含む）。
class LocalDataScopeUnauthenticated extends LocalDataScope {
  const LocalDataScopeUnauthenticated();
}

/// 認証済み。以降の全ローカルクエリ・Outbox・下書きは [ownerId] で絞る。
class LocalDataScopeAuthenticated extends LocalDataScope {
  const LocalDataScopeAuthenticated(this.ownerId);

  final String ownerId;

  @override
  bool operator ==(Object other) =>
      other is LocalDataScopeAuthenticated && other.ownerId == ownerId;

  @override
  int get hashCode => ownerId.hashCode;
}

/// [LocalDataScope] から現在の owner を取り出す（未認証/復元中は null）。
extension LocalDataScopeOwner on LocalDataScope {
  String? get ownerIdOrNull => this is LocalDataScopeAuthenticated
      ? (this as LocalDataScopeAuthenticated).ownerId
      : null;
}
