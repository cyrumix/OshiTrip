import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'app_card.dart';

/// 今後の現場カード（design-spec §4/§6.3・一覧刷新: デジタル半券 v2）。
///
/// カード全体を1枚の半券（チケット）として設計する:
/// - **券面**（上）: 日付・「あと◯日」・アーティスト名（主役）・公演名・会場・状態
/// - **ミシン目**: 左右両端の半円ノッチ＋破線で券面と半券を物理的に区切る
/// - **半券**（下）: 準備ステータスを**等幅タイル**で並べ、直下に「次にやる」1行
///
/// 推しカラーはアクセント（券面左の色帯）のみに使い、本文の可読性を壊さない（§2）。
/// 色は ColorScheme / [AppTokens] に追従し、ダークテーマでも破綻しない。
///
/// [minimal] = true のときは券面だけの最小構成にする（HOMEの今後の現場: 準備状況や
/// 次アクションは詳細画面で確認する方針）。
class EventListCard extends StatelessWidget {
  const EventListCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.accentColor,
    this.subtitle,
    this.venue,
    this.daysUntil,
    this.statusChips = const <Widget>[],
    this.prepTiles = const <Widget>[],
    this.nextAction,
    this.onTap,
    this.minimal = false,
  });

  final String title;

  /// アーティスト名など。指定時は券面の主見出しとして公演名より目立たせる。
  final String? subtitle;
  final String dateLabel;
  final String? venue;

  /// 残日数（null = 非表示。過去は負値で「n日前」）。
  final int? daysUntil;

  /// 推しカラー罫線（推し未設定時はユーザーの推しカラー等のフォールバック）。
  final Color accentColor;

  /// 状態バッジ（準備中/本日/中止 等）。券面の会場の下に小さく並べる。
  final List<Widget> statusChips;

  /// 準備ステータスのタイル群（半券に**等幅**で並べる。各タイルは Expanded 化する）。
  final List<Widget> prepTiles;

  /// 「次にやる」等の全幅1行（半券のタイル列の直下）。
  final Widget? nextAction;
  final VoidCallback? onTap;

  /// 最小構成（券面のみ・半券を出さない）。
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final hasStub = !minimal && (prepTiles.isNotEmpty || nextAction != null);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Face(
            theme: theme,
            tokens: tokens,
            title: title,
            subtitle: subtitle,
            dateLabel: dateLabel,
            venue: venue,
            daysUntil: daysUntil,
            accentColor: accentColor,
            statusChips: statusChips,
            minimal: minimal,
            tightBottom: hasStub,
          ),
          if (hasStub) ...[
            _TicketPerforation(
              notchColor: tokens.backgroundBottom,
              dashColor: tokens.divider,
            ),
            // 半券: 券面よりわずかに淡いラベンダーの面で「切り取り」感を出す。
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.primarySoft.withValues(alpha: .18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.md,
                  AppSpace.lg,
                  AppSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (prepTiles.isNotEmpty) _PrepTileRow(tiles: prepTiles),
                    if (nextAction != null) ...[
                      if (prepTiles.isNotEmpty)
                        const SizedBox(height: AppSpace.sm),
                      nextAction!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 券面（日付・残日数・アーティスト名・公演名・会場・状態）。
class _Face extends StatelessWidget {
  const _Face({
    required this.theme,
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    required this.venue,
    required this.daysUntil,
    required this.accentColor,
    required this.statusChips,
    required this.minimal,
    required this.tightBottom,
  });

  final ThemeData theme;
  final AppTokens tokens;
  final String title;
  final String? subtitle;
  final String dateLabel;
  final String? venue;
  final int? daysUntil;
  final Color accentColor;
  final List<Widget> statusChips;
  final bool minimal;
  final bool tightBottom;

  @override
  Widget build(BuildContext context) {
    final days = daysUntil;
    final daysText = days == null
        ? null
        : days == 0
            ? '本日'
            : days > 0
                ? 'あと$days日'
                : '${-days}日前';
    final daysSemantics = days == null
        ? null
        : days == 0
            ? '公演は本日です'
            : days > 0
                ? '公演まであと$days日'
                : '公演から${-days}日経過';
    // 残7日以内（当日含む）は「近づく夜明け」として温度を上げる。
    final isSoon = days != null && days >= 0 && days <= 7;
    final isPast = days != null && days < 0;

    final daysWidget = daysText == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: isSoon
                  ? null
                  : isPast
                      ? theme.colorScheme.surfaceContainerHighest
                      : tokens.primarySoft,
              gradient: isSoon
                  ? LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: .20),
                        tokens.dawn.withValues(alpha: .26),
                      ],
                    )
                  : null,
            ),
            child: Text(
              daysText,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSoon
                    ? (theme.brightness == Brightness.light
                        ? const Color(0xFF7A2C4E)
                        : const Color(0xFFFFD9E6))
                    : isPast
                        ? tokens.textSecondary
                        : theme.colorScheme.primary,
                fontWeight: isSoon ? FontWeight.w800 : FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              semanticsLabel: daysSemantics,
            ),
          );

    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        AppSpace.lg - 2,
        AppSpace.lg,
        tightBottom ? AppSpace.md : AppSpace.lg - 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  dateLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (daysWidget != null) daysWidget,
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          if (minimal) ...[
            // 会場（文脈）→ 公演名（見出し）の編集的な階層（§3）。
            if (venue != null)
              Text(
                venue!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: tokens.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            // アーティスト名（主役）→ 公演名 → 会場 の券面階層。
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              Text(
                subtitle!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (venue != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 13,
                    color: tokens.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      venue!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: tokens.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (statusChips.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              children: statusChips,
            ),
          ],
        ],
      ),
    );

    return Stack(
      children: [
        // 面: 白〜淡紫のごく控えめな斜めグラデーション（券面の紙面。単色にしない）。
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.transparent,
                    tokens.primarySoft.withValues(alpha: .28),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 推しカラーの色帯（券面左端のアクセント, §2）。
        Positioned(
          left: 10,
          top: AppSpace.md,
          bottom: AppSpace.md,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor,
                  accentColor.withValues(alpha: .40),
                ],
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }
}

/// 準備タイルを**常に等幅**の1行に並べる（Wrap を使わず Row+Expanded, §レイアウト）。
class _PrepTileRow extends StatelessWidget {
  const _PrepTileRow({required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

/// 券面と半券の境界（左右両端の半円ノッチ＋破線）。ノッチはカード背後の
/// 背景色で塗って「切り込み」に見せる。高さ固定なので Dynamic Type でも崩れない。
class _TicketPerforation extends StatelessWidget {
  const _TicketPerforation({required this.notchColor, required this.dashColor});

  final Color notchColor;
  final Color dashColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      width: double.infinity,
      child: CustomPaint(
        painter:
            _PerforationPainter(notchColor: notchColor, dashColor: dashColor),
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({
    required this.notchColor,
    required this.dashColor,
  });

  final Color notchColor;
  final Color dashColor;

  static const double _notchRadius = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final notch = Paint()
      ..color = notchColor
      ..isAntiAlias = true;
    // 左右端に背景色の半円を描いて、券面/半券の「切り込み」を作る。
    canvas.drawCircle(Offset(0, y), _notchRadius, notch);
    canvas.drawCircle(Offset(size.width, y), _notchRadius, notch);

    // ノッチの間を破線で結ぶ。
    final dash = Paint()
      ..color = dashColor
      ..strokeWidth = 1;
    const dashW = 4.0;
    const gapW = 4.0;
    var x = _notchRadius + 3;
    final endX = size.width - _notchRadius - 3;
    while (x < endX) {
      final segEnd = (x + dashW) < endX ? x + dashW : endX;
      canvas.drawLine(Offset(x, y), Offset(segEnd, y), dash);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter old) =>
      old.notchColor != notchColor || old.dashColor != dashColor;
}
