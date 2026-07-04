import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/design_system/design_system.dart';
import '../../../../core/images/image_store.dart';
import '../../../../core/providers.dart';
import '../../../genba/domain/genba.dart';
import '../../../genba/domain/genba_schedule.dart';

/// 当日ホームカード（§6.2）。
///
/// チケット・会場・時刻・座席/整理番号・集合場所・重要Todo・交通・宿泊へ
/// 少ないタップでアクセスできる。終演予定後は「余韻中」表示に切り替わる。
/// 外部チケットURLと保存済みチケット画像はボタンを分けて明確に区別する。
class TodayCard extends StatelessWidget {
  const TodayCard({super.key, required this.aggregate, required this.now});

  final GenbaAggregate aggregate;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final status = deriveGenbaStatus(aggregate.genba, now);
    if (status == GenbaStatus.afterglow) {
      return _AfterglowCard(aggregate: aggregate);
    }
    return _TodayModeCard(aggregate: aggregate, now: now);
  }
}

class _TodayModeCard extends StatelessWidget {
  const _TodayModeCard({required this.aggregate, required this.now});

  final GenbaAggregate aggregate;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final genba = aggregate.genba;
    final ticket = _mainTicket(aggregate.tickets);
    final meetupMemo = aggregate.memoOf(MemoCategory.meetup);
    final urgentTodos = aggregate.todos
        .where((t) => !t.isDone && t.priority == TodoPriority.high)
        .toList();
    final outbound = aggregate.transports
        .where((t) => t.direction == TransportDirection.outbound)
        .toList();
    final inbound = aggregate.transports
        .where((t) => t.direction == TransportDirection.inbound)
        .toList();
    const fg = Colors.white;

    // 当日は「明けた空」: 菫→薔薇→暁のグラデーションで夜明けを告げる
    // （HOME刷新デザイン案・フレーム④）。
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, .55, 1],
            colors: [
              tokens.todayGradientStart,
              tokens.todayGradientMid,
              tokens.todayGradientEnd,
            ],
          ),
        ),
        child: InkWell(
          onTap: () => context.push('/genba/${genba.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.today, color: fg, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '本日の現場',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  genba.title,
                  style: theme.textTheme.titleLarge?.copyWith(color: fg),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  genba.artistName,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: fg.withValues(alpha: .9)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: '会場',
                  value: genba.venue ?? '未登録',
                ),
                _InfoRow(
                  icon: Icons.schedule,
                  label: '開場/開演/終演',
                  value: [
                    genba.doorTimeMinutes == null
                        ? '-'
                        : formatMinutes(genba.doorTimeMinutes!),
                    genba.startTimeMinutes == null
                        ? '-'
                        : formatMinutes(genba.startTimeMinutes!),
                    genba.endTimeMinutes == null
                        ? '-'
                        : formatMinutes(genba.endTimeMinutes!),
                  ].join(' / '),
                ),
                if (ticket != null)
                  _InfoRow(
                    icon: Icons.confirmation_number_outlined,
                    label: '座席/整理番号',
                    value: [
                      if (ticket.seat != null && ticket.seat!.isNotEmpty)
                        ticket.seat!,
                      if (ticket.entryNumber != null &&
                          ticket.entryNumber!.isNotEmpty)
                        '整理番号 ${ticket.entryNumber!}',
                      if (ticket.gate != null && ticket.gate!.isNotEmpty)
                        '入場口 ${ticket.gate!}',
                    ].join(' / ').ifEmpty('未登録'),
                  ),
                if (meetupMemo != null && meetupMemo.body.isNotEmpty)
                  _InfoRow(
                    icon: Icons.groups_outlined,
                    label: '集合場所',
                    value: meetupMemo.body,
                  ),
                if (urgentTodos.isNotEmpty)
                  _InfoRow(
                    icon: Icons.priority_high,
                    label: '重要Todo',
                    value: urgentTodos.map((t) => t.name).join('、'),
                  ),
                if (outbound.isNotEmpty)
                  _InfoRow(
                    icon: Icons.arrow_circle_right_outlined,
                    label: '往路',
                    value: _transportSummary(outbound.first),
                  ),
                if (inbound.isNotEmpty)
                  _InfoRow(
                    icon: Icons.arrow_circle_left_outlined,
                    label: '復路',
                    value: _transportSummary(inbound.first),
                  ),
                if (aggregate.lodgings.isNotEmpty)
                  _InfoRow(
                    icon: Icons.hotel_outlined,
                    label: '宿泊',
                    value: aggregate.lodgings.first.name ?? '登録済み',
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (ticket?.url != null && ticket!.url!.isNotEmpty)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF41307F),
                        ),
                        onPressed: () => _openUrl(context, ticket.url!),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('チケットサイトを開く'),
                      ),
                    if (ticket?.imageLocalPath != null)
                      Consumer(
                        builder: (context, ref, _) => FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: .18),
                            foregroundColor: fg,
                          ),
                          onPressed: () => _showTicketImage(
                            context,
                            ref.read(imageStoreProvider),
                            ticket!.ownerId,
                            ticket.imageLocalPath!,
                          ),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('保存済みチケット画像'),
                        ),
                      ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: fg,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: .55),
                        ),
                      ),
                      onPressed: () => context.push('/genba/${genba.id}'),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('現場の詳細'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Ticket? _mainTicket(List<Ticket> tickets) {
    if (tickets.isEmpty) return null;
    for (final t in tickets) {
      if (t.acquisitionStatus == TicketAcquisition.acquired) return t;
    }
    return tickets.first;
  }

  String _transportSummary(Transport t) => [
        if (t.method != null && t.method!.isNotEmpty) t.method!,
        if (t.departAt != null)
          '${t.departAt!.toLocal().hour}:${t.departAt!.toLocal().minute.toString().padLeft(2, '0')}発',
        if (t.fromPlace != null && t.fromPlace!.isNotEmpty)
          '${t.fromPlace}→${t.toPlace ?? ''}',
      ].join(' ').ifEmpty('登録済み');

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('URLを開けませんでした')));
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showTicketImage(
    BuildContext context,
    ImageStore store,
    String ownerId,
    String ref,
  ) {
    final file = store.tryResolveOwned(ownerId, ref);
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '保存済みチケット画像（センシティブ情報に注意）',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Flexible(
              child: file == null
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('画像を読み込めませんでした'),
                    )
                  : Image.file(
                      file,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('画像を読み込めませんでした'),
                      ),
                    ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 終演予定後の「余韻中」表示（§6.2）。
class _AfterglowCard extends StatelessWidget {
  const _AfterglowCard({required this.aggregate});

  final GenbaAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final genba = aggregate.genba;
    // 終演後の「余韻」: 暁の名残り（dawn の淡い面）で静かに包む。
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      color: theme.colorScheme.surface,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tokens.primarySoft.withValues(alpha: .55),
              tokens.dawn.withValues(alpha: .22),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '余韻中',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                genba.title,
                style: theme.textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text('おつかれさまでした！今の気持ちをひとこと残しませんか？'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.push('/memories/${genba.id}/edit'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  '短い感想を書く',
                  semanticsLabel: '短い感想の入力へ進む',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: fg.withValues(alpha: .9)),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: fg.withValues(alpha: .85)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
