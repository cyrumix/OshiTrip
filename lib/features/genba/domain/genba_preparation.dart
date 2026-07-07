import 'genba.dart';

/// カテゴリ（チケット/交通/宿泊）の準備状態。
/// 「不要」[notRequired] と「未登録」[notRegistered] を区別し、
/// 不要は未完了数・リマインド候補に含めない（§7.4/§7.5）。
enum CategoryPrepState { notRequired, notRegistered, inProgress, ready }

extension CategoryPrepStateLabel on CategoryPrepState {
  String get label => switch (this) {
        CategoryPrepState.notRequired => '不要',
        CategoryPrepState.notRegistered => '未登録',
        CategoryPrepState.inProgress => '準備中',
        CategoryPrepState.ready => '準備OK',
      };

  bool get needsAttention =>
      this == CategoryPrepState.notRegistered ||
      this == CategoryPrepState.inProgress;
}

/// 持ち物専用の準備状態（§持ち物の準備ステータス）。
///
/// チケット/交通/宿泊と違い「不要」の概念を持たない（持ち物は常に対象で、
/// 要否を答える項目ではない）。ラベルもTodo系とは別語（「未対応」）にするため
/// [CategoryPrepState] を流用せず専用のenumとして定義する。
enum BelongingPrepState { notRegistered, pending, ready }

extension BelongingPrepStateLabel on BelongingPrepState {
  String get label => switch (this) {
        BelongingPrepState.notRegistered => '未登録',
        BelongingPrepState.pending => '未対応',
        BelongingPrepState.ready => '準備OK',
      };

  bool get needsAttention =>
      this == BelongingPrepState.notRegistered ||
      this == BelongingPrepState.pending;
}

/// 現場の準備サマリ（ホームカード表示用）。
class GenbaPreparation {
  const GenbaPreparation({
    required this.ticket,
    required this.transport,
    required this.lodging,
    required this.incompleteTodoCount,
    required this.belonging,
  });

  final CategoryPrepState ticket;
  final CategoryPrepState transport;
  final CategoryPrepState lodging;
  final int incompleteTodoCount;

  /// 持ち物の準備状態（未登録/未対応/準備OK）。件数ではなく状態で示す
  /// （Todoは「残り件数」、持ち物は「対応状況」という別集計のため, §集計）。
  final BelongingPrepState belonging;

  /// リマインド対象となる未完了項目数。「不要」は含めない。
  int get attentionCount {
    var count = incompleteTodoCount;
    if (ticket.needsAttention) count++;
    if (transport == CategoryPrepState.notRegistered) count++;
    if (lodging == CategoryPrepState.notRegistered) count++;
    return count;
  }

  static GenbaPreparation of(GenbaAggregate aggregate) {
    return GenbaPreparation(
      ticket: _ticketState(aggregate.tickets),
      transport: _transportState(
        aggregate.genba.transportRequirement,
        aggregate.transports,
      ),
      lodging: _lodgingState(
        aggregate.genba.lodgingRequirement,
        aggregate.lodgings,
      ),
      incompleteTodoCount: aggregate.incompleteTodoCount,
      belonging: _belongingState(aggregate.todos),
    );
  }

  static BelongingPrepState _belongingState(List<GenbaTodo> todos) {
    final belongings =
        todos.where((t) => t.type == TodoItemType.belonging).toList();
    if (belongings.isEmpty) return BelongingPrepState.notRegistered;
    return belongings.every((t) => t.isDone)
        ? BelongingPrepState.ready
        : BelongingPrepState.pending;
  }

  static CategoryPrepState _ticketState(List<Ticket> tickets) {
    if (tickets.isEmpty) return CategoryPrepState.notRegistered;
    if (tickets.any((t) => t.acquisitionStatus == TicketAcquisition.acquired)) {
      return CategoryPrepState.ready;
    }
    return CategoryPrepState.inProgress;
  }

  static CategoryPrepState _transportState(
    RequirementStatus requirement,
    List<Transport> transports,
  ) {
    if (requirement == RequirementStatus.notRequired) {
      return CategoryPrepState.notRequired;
    }
    if (transports.isEmpty) {
      // 要否未回答かつ未登録の場合も、催促はしないが「未登録」を表示する。
      return CategoryPrepState.notRegistered;
    }
    final hasOutbound =
        transports.any((t) => t.direction == TransportDirection.outbound);
    final hasInbound =
        transports.any((t) => t.direction == TransportDirection.inbound);
    return hasOutbound && hasInbound
        ? CategoryPrepState.ready
        : CategoryPrepState.inProgress;
  }

  static CategoryPrepState _lodgingState(
    RequirementStatus requirement,
    List<Lodging> lodgings,
  ) {
    if (requirement == RequirementStatus.notRequired) {
      return CategoryPrepState.notRequired;
    }
    if (lodgings.isEmpty) return CategoryPrepState.notRegistered;
    return CategoryPrepState.ready;
  }
}

/// ホームカードに出す「次に行う1アクション」。
class NextAction {
  const NextAction(this.label, this.kind);

  final String label;
  final NextActionKind kind;
}

enum NextActionKind {
  ticket,
  todo,
  transport,
  lodging,
  expedition,
  memory,
  none
}

/// 次アクションの導出（優先順位つき・純粋関数）。
NextAction? deriveNextAction(GenbaAggregate aggregate, DateTime now) {
  final genba = aggregate.genba;
  if (genba.isCanceled) return null;

  final prep = GenbaPreparation.of(aggregate);

  if (prep.ticket == CategoryPrepState.notRegistered) {
    return const NextAction('チケット情報を登録する', NextActionKind.ticket);
  }

  // 持ち物には期限・重要度が無いため対象外にする（§「次にやる」判定）。
  // 持ち物の状況は独立した準備ステータス（[BelongingPrepState]）で知らせる。
  final urgentTodo = aggregate.todos
      .where((t) => t.type == TodoItemType.todo && !t.isDone)
      .where(
        (t) =>
            t.priority == TodoPriority.high ||
            (t.dueDate != null && t.dueDate!.difference(now).inDays <= 3),
      )
      .toList()
    ..sort((a, b) {
      final byPriority = b.priority.index.compareTo(a.priority.index);
      if (byPriority != 0) return byPriority;
      final ad = a.dueDate, bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
  if (urgentTodo.isNotEmpty) {
    return NextAction(
      'Todo「${urgentTodo.first.name}」を完了する',
      NextActionKind.todo,
    );
  }

  if (genba.transportRequirement == RequirementStatus.required &&
      prep.transport == CategoryPrepState.notRegistered) {
    return const NextAction('交通を登録する', NextActionKind.transport);
  }
  if (genba.lodgingRequirement == RequirementStatus.required &&
      prep.lodging == CategoryPrepState.notRegistered) {
    return const NextAction('宿泊を登録する', NextActionKind.lodging);
  }
  if (genba.isExpedition == null &&
      genba.transportRequirement == RequirementStatus.unknown &&
      genba.lodgingRequirement == RequirementStatus.unknown) {
    return const NextAction('遠征の要否を設定する', NextActionKind.expedition);
  }
  if (prep.ticket == CategoryPrepState.inProgress) {
    return const NextAction('チケットの状況を更新する', NextActionKind.ticket);
  }
  return null;
}
