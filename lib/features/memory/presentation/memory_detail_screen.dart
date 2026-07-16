import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/failure.dart';
import '../../../core/images/image_status_provider.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/async_view.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba.dart';
import '../../genba/domain/genba_schedule.dart';
import '../../genba/presentation/widgets/action_feedback.dart';
import '../application/memory_actions_controller.dart';
import '../application/memory_controllers.dart';
import '../domain/memory.dart';
import 'memory_edit_sheets.dart';

/// 思い出詳細＝その日のページ（design-spec §9・再設計 D-252/M2）。
///
/// タブでデータを分類せず、縦スクロールの1本のストーリーとして構成する。
/// **空のセクションは表示しない**。現場に登録済みのデータ（会場・チケットの座席・
/// 交通・宿泊）を思い出へ**自動で引き継いで**再掲し、「終わった現場がそのまま残って
/// いる」ことを可視化する（本質の中核）。写真がなくても感想やセトリを主役にできる。
class MemoryDetailScreen extends ConsumerWidget {
  const MemoryDetailScreen({super.key, required this.genbaId});

  final String genbaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aggregateAsync = ref.watch(genbaByIdProvider(genbaId));
    final bundleAsync = ref.watch(memoryBundleProvider(genbaId));

    return Scaffold(
      body: AsyncValueView<GenbaAggregate?>(
        value: aggregateAsync,
        isEmpty: (a) => a == null,
        loadingView: const LoadingSkeleton.hero(cardCount: 2),
        emptyView: const EmptyView(message: '思い出が見つかりませんでした'),
        data: (aggregate) {
          final genba = aggregate!.genba;
          // 記録（bundle）の読み込み中・失敗を「記録なし」へ変換しない（§15）。
          return AsyncValueView<MemoryBundle>(
            value: bundleAsync,
            loadingView: const LoadingSkeleton.hero(cardCount: 2),
            onRetry: () => ref.invalidate(memoryBundleProvider(genbaId)),
            data: (bundle) => CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  title: Text(genba.title, overflow: TextOverflow.ellipsis),
                  actions: [
                    if (bundle.photos.isNotEmpty)
                      IconButton(
                        tooltip: '思い出アルバム',
                        icon: const Icon(Icons.photo_library_outlined),
                        onPressed: () =>
                            context.push('/memories/$genbaId/album'),
                      ),
                  ],
                ),
                if (bundle.photos.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _PhotoCarousel(photos: bundle.photos),
                  ),
                SliverToBoxAdapter(
                  child: _MetaSection(genba: genba, bundle: bundle),
                ),
                // ストーリー各セクションを個別の sliver にして、画面外セクションを
                // 遅延ビルド/カリングできるようにする（大量記録時の負荷軽減, レビュー是正）。
                ..._buildStorySlivers(
                  context,
                  genbaId: genbaId,
                  aggregate: aggregate,
                  bundle: bundle,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'memory_fab',
        // 巨大フォームではなく、記録するセクションを選ぶ入口（§9・M3）。
        onPressed: () => showMemoryRecordMenu(context, genbaId: genbaId),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('記録する'),
      ),
    );
  }
}

/// その日を上から下へ読み返すストーリーを、セクションごとの sliver で返す
/// （空セクションは出さない・§9）。個別 sliver 化で画面外は遅延ビルドされる。
List<Widget> _buildStorySlivers(
  BuildContext context, {
  required String genbaId,
  required GenbaAggregate aggregate,
  required MemoryBundle bundle,
}) {
  final entry = bundle.entry;

  // 現場から引き継ぐ座席（チケットの seat）。
  final seats = [
    for (final t in aggregate.tickets)
      if ((t.seat ?? '').trim().isNotEmpty) t.seat!.trim(),
  ];
  final hasPhotos = bundle.photos.isNotEmpty;
  final hasImpression = (entry?.impression.isNotEmpty ?? false) ||
      (entry?.bestMoment.isNotEmpty ?? false);
  final hasSetlist = bundle.setlist.isNotEmpty;
  final hasDayRecord = seats.isNotEmpty ||
      (entry?.seatView.isNotEmpty ?? false) ||
      (entry?.mcNotes.isNotEmpty ?? false) ||
      aggregate.genba.manualEndedAt != null;
  final hasExpedition = aggregate.transports.isNotEmpty ||
      aggregate.lodgings.isNotEmpty ||
      bundle.places.isNotEmpty ||
      bundle.goods.isNotEmpty;
  final tags = entry?.tags ?? const <String>[];

  // 写真だけの思い出も「記録なし」ではない（カルーセルは表示済み, レビュー是正）。
  final anyContent = hasPhotos ||
      hasImpression ||
      hasSetlist ||
      hasDayRecord ||
      hasExpedition ||
      tags.isNotEmpty;

  if (!anyContent) {
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xl),
          child: Column(
            children: [
              const EmptyView(
                icon: Icons.auto_awesome,
                message: 'まだ記録がありません',
                description: '写真やひとことから、気軽に残しはじめられます。',
              ),
              const SizedBox(height: AppSpace.md),
              FilledButton.icon(
                onPressed: () => context.push('/memories/$genbaId/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('最初の記録をする'),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void openSheet(MemorySection section) =>
      showMemorySectionSheet(context, genbaId: genbaId, section: section);

  return [
    if (hasImpression)
      SliverToBoxAdapter(
        child: _MemorySection(
          title: '感想',
          onEdit: () => openSheet(MemorySection.impression),
          child: _ImpressionView(entry: entry!),
        ),
      ),
    if (hasSetlist)
      SliverToBoxAdapter(
        child: _MemorySection(
          title: 'セトリ',
          onEdit: () => openSheet(MemorySection.setlist),
          child: _SetlistView(setlist: bundle.setlist),
        ),
      ),
    if (hasDayRecord)
      SliverToBoxAdapter(
        child: _MemorySection(
          title: 'その日の記録',
          onEdit: () => openSheet(MemorySection.dayRecord),
          child: _DayRecordView(
            genba: aggregate.genba,
            seats: seats,
            seatView: entry?.seatView ?? '',
            mcNotes: entry?.mcNotes ?? '',
          ),
        ),
      ),
    if (hasExpedition)
      SliverToBoxAdapter(
        child: _MemorySection(
          title: '遠征の記録',
          // 現場に登録済みの交通・宿泊は自動で引き継いで読み取り専用で再掲する。
          trailing: _CarryoverBadge(),
          // グッズ・場所・食べものの編集はフル記録画面へ（写真紐づけが込み入るため）。
          onEdit: () => context.push('/memories/$genbaId/edit'),
          child: _ExpeditionView(
            transports: aggregate.transports,
            lodgings: aggregate.lodgings,
            places: bundle.places,
            goods: bundle.goods,
          ),
        ),
      ),
    if (tags.isNotEmpty)
      SliverToBoxAdapter(
        child: _MemorySection(
          title: 'タグ',
          onEdit: () => openSheet(MemorySection.tags),
          child: Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [for (final tag in tags) Chip(label: Text(tag))],
          ),
        ),
      ),
    SliverToBoxAdapter(
      child: _AddMoreChips(
        genbaId: genbaId,
        // 表示ラベルと遷移先を分離（文言変更・多言語化に強い, レビュー是正）。
        // section == null は遠征＝フル記録画面。
        missing: [
          if (!hasImpression) (label: '感想', section: MemorySection.impression),
          if (!hasSetlist) (label: 'セトリ', section: MemorySection.setlist),
          if (!hasPhotos) (label: '写真', section: MemorySection.photos),
          if (!hasDayRecord) (label: '座席・メモ', section: MemorySection.dayRecord),
          if (tags.isEmpty) (label: 'タグ', section: MemorySection.tags),
          if (!hasExpedition) (label: '遠征の記録', section: null),
        ],
      ),
    ),
  ];
}

/// セクションの共通枠（見出し＋任意の trailing＋「編集」＋本文）。
/// 編集はそのセクションだけのボトムシートで行い、閲覧と分離する（§9・M3）。
class _MemorySection extends StatelessWidget {
  const _MemorySection({
    required this.title,
    required this.child,
    this.trailing,
    this.onEdit,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpace.sm),
                trailing!,
              ],
              const Spacer(),
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('編集'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          child,
        ],
      ),
    );
  }
}

/// 現場から自動で引き継いだ内容であることを示す小さなバッジ。
class _CarryoverBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        '現場から自動',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 追記チップ1件（表示ラベルと遷移先セクションを分離。section==null は遠征＝
/// フル記録画面へ）。文言変更・多言語化で遷移先が変わらない（レビュー是正）。
typedef _AddMoreItem = ({String label, MemorySection? section});

/// まだ無いセクションを追記へ誘導するチップ列（§9）。
class _AddMoreChips extends StatelessWidget {
  const _AddMoreChips({required this.genbaId, required this.missing});

  final String genbaId;
  final List<_AddMoreItem> missing;

  @override
  Widget build(BuildContext context) {
    if (missing.isEmpty) return const SizedBox.shrink();
    final tokens = AppTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '追記できること',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              for (final item in missing)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text('${item.label}を追加'),
                  onPressed: () {
                    final section = item.section;
                    if (section != null) {
                      showMemorySectionSheet(
                        context,
                        genbaId: genbaId,
                        section: section,
                      );
                    } else {
                      context.push('/memories/$genbaId/edit');
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 大型写真カルーセル + 現在位置 1/N（§9）。
class _PhotoCarousel extends ConsumerStatefulWidget {
  const _PhotoCarousel({required this.photos});

  final List<MemoryPhoto> photos;

  @override
  ConsumerState<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends ConsumerState<_PhotoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final current = photos[_index.clamp(0, photos.length - 1)];
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _CarouselPhoto(photo: photos[i]),
          ),
        ),
        Positioned(
          right: AppSpace.md,
          bottom: AppSpace.md,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '${_index + 1}/${photos.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              semanticsLabel: '写真 ${photos.length}枚中 ${_index + 1}枚目',
            ),
          ),
        ),
        // アップロード状態は必要時のみ表示（成功していない同期を成功と
        // 見せない, §12.1/§13）。失敗はその場で再試行できる。
        if (current.uploadStatus != PhotoUploadStatus.uploaded)
          Positioned(
            left: AppSpace.md,
            bottom: AppSpace.md,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SyncBadge(
                  status: switch (current.uploadStatus) {
                    PhotoUploadStatus.queued => SyncBadgeStatus.syncing,
                    PhotoUploadStatus.failed => SyncBadgeStatus.failed,
                    _ => SyncBadgeStatus.savedLocally,
                  },
                ),
                if (current.uploadStatus == PhotoUploadStatus.failed)
                  IconButton(
                    tooltip: 'アップロードを再試行',
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      final failure = await ref
                          .read(
                            memoryEditControllerProvider(current.genbaId)
                                .notifier,
                          )
                          .uploadPhoto(current);
                      if (failure is Failure && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(failure.message)),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// カルーセル1枚分。写真あり／端末に実体なし／削除済み（missing）／
/// 権限・ロックで読めない（inaccessible）／読込失敗を区別し、対応可能な
/// 状態には再試行・再選択の導線を出す（design-spec §12 / R7）。
class _CarouselPhoto extends ConsumerStatefulWidget {
  const _CarouselPhoto({required this.photo});

  final MemoryPhoto photo;

  @override
  ConsumerState<_CarouselPhoto> createState() => _CarouselPhotoState();
}

class _CarouselPhotoState extends ConsumerState<_CarouselPhoto> {
  /// 読込失敗からの再試行回数（Image を作り直すためのキー）。
  int _attempt = 0;

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final localRef = photo.localPath;
    if (localRef == null) {
      // 端末に実体が無い（他端末で追加され画像本体は未取得、など）。
      return _PhotoFallback(
        icon: Icons.cloud_outlined,
        message: photo.storagePath != null
            ? 'この端末に写真の実体がありません\n（他の端末で追加された写真です）'
            : 'この写真を表示できません',
      );
    }
    final key = (ownerId: photo.ownerId, ref: localRef);
    final status = ref.watch(imageAssetStatusProvider(key));
    return switch (status) {
      ImageAssetStatus.missing => _PhotoFallback(
          message: '写真ファイルが見つかりません\n（端末から削除された可能性があります）',
          actionLabel: '写真を選び直す',
          onAction: () => context.push('/memories/${photo.genbaId}/edit'),
        ),
      ImageAssetStatus.inaccessible => _PhotoFallback(
          icon: Icons.lock_outline,
          message: '写真を読み込めません\n（権限がないか、端末がロック中の可能性があります）',
          actionLabel: '再試行',
          onAction: () => ref.invalidate(imageAssetStatusProvider(key)),
        ),
      ImageAssetStatus.present => _presentImage(photo, localRef),
    };
  }

  Widget _presentImage(MemoryPhoto photo, String localRef) {
    final file =
        ref.read(imageStoreProvider).tryResolveOwned(photo.ownerId, localRef);
    if (file == null) {
      return const _PhotoFallback(message: 'この写真を表示できません');
    }
    return Semantics(
      image: true,
      label: photo.caption ?? '思い出の写真',
      child: Image.file(
        file,
        key: ValueKey('photo-${photo.id}-$_attempt'),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PhotoFallback(
          message: 'この写真を読み込めませんでした',
          actionLabel: '再試行',
          onAction: () async {
            await FileImage(file).evict();
            if (mounted) setState(() => _attempt++);
          },
        ),
      ),
    );
  }
}

/// 写真を表示できないときの縮退面。理由をアイコン＋文言で示し（§14）、
/// 装飾用プレースホルダーと区別する。
class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({
    required this.message,
    this.icon = Icons.image_not_supported_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: AppSpace.sm),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpace.xs),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 日付・公演名・会場・記録件数・お気に入り（§9）。
class _MetaSection extends ConsumerWidget {
  const _MetaSection({required this.genba, required this.bundle});

  final Genba genba;
  final MemoryBundle bundle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final isFavorite = bundle.entry?.isFavorite ?? false;
    // 書き込みは application 層（R7）。進行中は再タップを受け付けない。
    final favoriteBusy = ref
        .watch(memoryActionsControllerProvider(genba.id))
        .contains(MemoryActionsController.favoriteKey);

    Future<void> toggleFavorite() async {
      final failure = await ref
          .read(memoryActionsControllerProvider(genba.id).notifier)
          .setFavorite(isFavorite: !isFavorite);
      if (context.mounted) handleActionResult(context, failure);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${genba.eventDate.year}/${genba.eventDate.month}/${genba.eventDate.day}'
                      '${genba.isCanceled ? '（中止）' : ''}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: tokens.textSecondary),
                    ),
                    Text(genba.artistName, style: theme.textTheme.titleSmall),
                    if (genba.venue != null) Text('会場: ${genba.venue}'),
                    if (genba.startTimeMinutes != null)
                      Text('開演 ${formatMinutes(genba.startTimeMinutes!)}'),
                  ],
                ),
              ),
              FavoriteButton(
                isFavorite: isFavorite,
                onPressed: favoriteBusy ? null : toggleFavorite,
                subjectLabel: genba.title,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.md,
            children: [
              if (genba.attendanceStatus == AttendanceStatus.attended)
                Chip(
                  avatar: const Icon(Icons.emoji_events_outlined, size: 16),
                  label: Text(AttendanceStatus.attended.label),
                  visualDensity: VisualDensity.compact,
                ),
              if (bundle.photos.isNotEmpty)
                Text(
                  '写真${bundle.photos.length}枚',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
              if (bundle.setlist.isNotEmpty)
                Text(
                  'セトリ${bundle.setlist.length}曲',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
              if (bundle.entry?.impression.isNotEmpty ?? false)
                Text(
                  '感想あり',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: tokens.textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 感想タブ: 日記カードとして読みやすい行間と余白（§9）。
class _ImpressionView extends StatelessWidget {
  const _ImpressionView({required this.entry});

  final MemoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final hasImpression = entry.impression.isNotEmpty;
    final hasBestMoment = entry.bestMoment.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImpression)
          AppCard(
            child: Text(
              entry.impression,
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8),
            ),
          ),
        if (hasBestMoment) ...[
          const SizedBox(height: AppSpace.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '特によかった曲・瞬間',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(entry.bestMoment),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SetlistView extends StatelessWidget {
  const _SetlistView({required this.setlist});

  final List<SetlistItem> setlist;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        children: [
          for (final item in setlist)
            ListTile(
              dense: true,
              leading: Text(
                '${item.position}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              title: Text(item.songTitle),
              subtitle: item.note == null ? null : Text(item.note!),
            ),
        ],
      ),
    );
  }
}

/// その日の記録: 座席（チケットから自動引き継ぎ）・見え方・MC・実際の終演時間（§9）。
class _DayRecordView extends StatelessWidget {
  const _DayRecordView({
    required this.genba,
    required this.seats,
    required this.seatView,
    required this.mcNotes,
  });

  final Genba genba;
  final List<String> seats;
  final String seatView;
  final String mcNotes;

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ended = genba.manualEndedAt?.toLocal();
    final rows = <Widget>[
      if (seats.isNotEmpty)
        _InfoRow(
          icon: Icons.event_seat_outlined,
          label: '座席',
          value: seats.join(' / '),
          carriedOver: true,
        ),
      if (seatView.isNotEmpty)
        _InfoRow(
          icon: Icons.visibility_outlined,
          label: '見え方',
          value: seatView,
        ),
      if (ended != null)
        _InfoRow(
          icon: Icons.nightlife_outlined,
          label: '実際の終演',
          value: _hhmm(ended),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rows.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpace.sm),
                  rows[i],
                ],
              ],
            ),
          ),
        if (mcNotes.isNotEmpty) ...[
          if (rows.isNotEmpty) const SizedBox(height: AppSpace.md),
          _NoteCard(title: 'MC・当日メモ', body: mcNotes),
        ],
      ],
    );
  }
}

/// 遠征の記録: 交通・宿泊（現場から自動引き継ぎ）＋行った場所・食べたもの・
/// グッズ（思い出の記録）を読み取り専用で再掲する（§9・本質の中核）。
class _ExpeditionView extends StatelessWidget {
  const _ExpeditionView({
    required this.transports,
    required this.lodgings,
    required this.places,
    required this.goods,
  });

  final List<Transport> transports;
  final List<Lodging> lodgings;
  final List<VisitedPlace> places;
  final List<GoodsItem> goods;

  static String _md(DateTime d) => '${d.month}/${d.day}';

  String _transportText(Transport t) {
    final parts = <String>[
      t.direction.label,
      if (t.methodDisplay.isNotEmpty) t.methodDisplay,
    ];
    final route = [
      if ((t.fromPlace ?? '').isNotEmpty) t.fromPlace!,
      if ((t.toPlace ?? '').isNotEmpty) t.toPlace!,
    ].join(' → ');
    final head = parts.join('・');
    return route.isEmpty ? head : '$head  $route';
  }

  String _lodgingText(Lodging l) {
    final name = (l.name ?? '').isNotEmpty ? l.name! : '宿泊';
    final ci = l.checkinDate;
    final co = l.checkoutDate;
    if (ci == null && co == null) return name;
    final span = [
      if (ci != null) _md(ci),
      if (co != null) _md(co),
    ].join('〜');
    return '$name（$span）';
  }

  @override
  Widget build(BuildContext context) {
    final spots = places.where((p) => p.category != 'food').toList();
    final foods = places.where((p) => p.category == 'food').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (transports.isNotEmpty)
          _DigestCard(
            icon: Icons.directions_transit_outlined,
            lines: [for (final t in transports) _transportText(t)],
          ),
        if (lodgings.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          _DigestCard(
            icon: Icons.hotel_outlined,
            lines: [for (final l in lodgings) _lodgingText(l)],
          ),
        ],
        if (spots.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          _DigestCard(
            icon: Icons.place_outlined,
            lines: [
              for (final p in spots)
                (p.memo ?? '').isEmpty ? p.name : '${p.name}（${p.memo}）',
            ],
          ),
        ],
        if (foods.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          _DigestCard(
            icon: Icons.restaurant_outlined,
            lines: [
              for (final p in foods)
                (p.memo ?? '').isEmpty ? p.name : '${p.name}（${p.memo}）',
            ],
          ),
        ],
        if (goods.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          _DigestCard(
            icon: Icons.shopping_bag_outlined,
            lines: [
              for (final g in goods)
                g.price == null
                    ? g.name
                    : '${g.name}  ¥${g.price} × ${g.quantity}',
            ],
          ),
        ],
      ],
    );
  }
}

/// アイコン＋複数行のダイジェストカード（読み取り専用）。
class _DigestCard extends StatelessWidget {
  const _DigestCard({required this.icon, required this.lines});

  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tokens.textSecondary),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  Text(lines[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 「ラベル: 値」の1行（座席・見え方など）。現場からの自動引き継ぎには印を付ける。
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.carriedOver = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool carriedOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: tokens.textSecondary),
        const SizedBox(width: AppSpace.sm),
        Text(
          '$label: ',
          style:
              theme.textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (carriedOver)
          Padding(
            padding: const EdgeInsets.only(left: AppSpace.sm),
            child: Icon(
              Icons.link,
              size: 14,
              color: tokens.textSecondary,
              semanticLabel: '現場から自動引き継ぎ',
            ),
          ),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(body),
        ],
      ),
    );
  }
}
