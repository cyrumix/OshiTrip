/// 通知の境界型（§8.3 / §11）。
///
/// 今回は「境界と土台」のみ: FCM/APNs 登録・スケジューリング・設定UI・
/// ディープリンク実処理は docs/follow-up-work.md 参照。
/// 通知価値が発生した時点で許可を求める方針のため、初回起動では
/// OS通知許可を要求しない（bootstrap にも通知初期化を置かない）。
enum NotificationKind {
  genbaApproaching,
  todoDueSoon,
  transportMissing,
  lodgingMissing,
  memoryAfterShow,
  memoryNextDay,
  memoryLater,
  anniversary,
  shareUpdated,
}

class NotificationPlan {
  const NotificationPlan({
    required this.kind,
    required this.genbaId,
    required this.fireAt,
    this.deepLinkPath,
  });

  final NotificationKind kind;
  final String genbaId;
  final DateTime fireAt;

  /// 通知タップで遷移するルート（go_router のパス）。
  final String? deepLinkPath;
}

/// 通知スケジューラ抽象（実装は後続）。
abstract interface class NotificationScheduler {
  Future<void> schedule(NotificationPlan plan);
  Future<void> cancelForGenba(String genbaId);
}
