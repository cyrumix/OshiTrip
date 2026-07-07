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

/// 思い出詳細の閲覧タブ（design-spec §9）。
enum _MemoryTab { impression, setlist, goods, notes }

extension on _MemoryTab {
  String get label => switch (this) {
        _MemoryTab.impression => '感想',
        _MemoryTab.setlist => 'セトリ',
        _MemoryTab.goods => 'グッズ',
        _MemoryTab.notes => 'メモ',
      };
}

/// 思い出詳細（design-spec §9）。
///
/// 最上部に写真カルーセル（1/N表示）、メタ情報とお気に入り、
/// 「感想／セトリ／グッズ／メモ」の閲覧タブ。写真がない場合は感想や
/// セトリを主役にできるレイアウトへ縮退する。編集入口はFAB（閲覧と分離）。
class MemoryDetailScreen extends ConsumerStatefulWidget {
  const MemoryDetailScreen({super.key, required this.genbaId});

  final String genbaId;

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  _MemoryTab _tab = _MemoryTab.impression;

  @override
  Widget build(BuildContext context) {
    final aggregateAsync = ref.watch(genbaByIdProvider(widget.genbaId));
    final bundleAsync = ref.watch(memoryBundleProvider(widget.genbaId));

    return Scaffold(
      body: AsyncValueView<GenbaAggregate?>(
        value: aggregateAsync,
        isEmpty: (a) => a == null,
        loadingView: const LoadingSkeleton.hero(cardCount: 2),
        emptyView: const EmptyView(message: '思い出が見つかりませんでした'),
        data: (aggregate) {
          final genba = aggregate!.genba;
          // 記録（bundle）の読み込み中・失敗を「記録なし」へ変換しない
          // （loading/error/data を正しく伝播する, §15）。
          return AsyncValueView<MemoryBundle>(
            value: bundleAsync,
            loadingView: const LoadingSkeleton.hero(cardCount: 2),
            onRetry: () => ref.invalidate(memoryBundleProvider(widget.genbaId)),
            data: (bundle) => CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  // AppBarTheme.backgroundColor は transparent（AppScaffold の
                  // 背景を透過させるため）。pinned な SliverAppBar は
                  // スクロール中の本文を隠す必要があるため、ここだけ不透明にする
                  // （透明のままだと本文がタイトル行に透けて重なる）。
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  title: Text(genba.title, overflow: TextOverflow.ellipsis),
                ),
                if (bundle.photos.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _PhotoCarousel(photos: bundle.photos),
                  ),
                SliverToBoxAdapter(
                  child: _MetaSection(genba: genba, bundle: bundle),
                ),
                if (bundle.hasAnyContent) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                      child: SegmentTabs(
                        tabs: [for (final t in _MemoryTab.values) t.label],
                        selectedIndex: _tab.index,
                        onSelected: (i) =>
                            setState(() => _tab = _MemoryTab.values[i]),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      // 控えめな切替（Reduce Motion 時は即時, §13/§14）。
                      duration: reduceMotionOf(context)
                          ? Duration.zero
                          : AppDurations.normal,
                      child: KeyedSubtree(
                        key: ValueKey(_tab),
                        child: _TabContent(tab: _tab, bundle: bundle),
                      ),
                    ),
                  ),
                ] else
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpace.xl),
                      child: EmptyView(
                        icon: Icons.auto_awesome,
                        message: 'まだ記録がありません',
                        description: '写真やひとことから、気軽に残しはじめられます。',
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'memory_fab',
        onPressed: () => context.push('/memories/${widget.genbaId}/edit'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('記録する'),
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
                    Text(
                      genba.artistName,
                      style: theme.textTheme.titleSmall,
                    ),
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

class _TabContent extends StatelessWidget {
  const _TabContent({required this.tab, required this.bundle});

  final _MemoryTab tab;
  final MemoryBundle bundle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: switch (tab) {
        _MemoryTab.impression => _ImpressionView(bundle: bundle),
        _MemoryTab.setlist => _SetlistView(bundle: bundle),
        _MemoryTab.goods => _GoodsView(bundle: bundle),
        _MemoryTab.notes => _NotesView(bundle: bundle),
      },
    );
  }
}

/// 感想タブ: 日記カードとして読みやすい行間と余白（§9）。
class _ImpressionView extends StatelessWidget {
  const _ImpressionView({required this.bundle});

  final MemoryBundle bundle;

  @override
  Widget build(BuildContext context) {
    final entry = bundle.entry;
    final hasImpression = entry?.impression.isNotEmpty ?? false;
    final hasBestMoment = entry?.bestMoment.isNotEmpty ?? false;
    if (!hasImpression && !hasBestMoment) {
      return const _TabEmpty(message: '感想はまだありません。「記録する」から残せます。');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImpression)
          AppCard(
            child: Text(
              entry!.impression,
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
                Text(entry!.bestMoment),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SetlistView extends StatelessWidget {
  const _SetlistView({required this.bundle});

  final MemoryBundle bundle;

  @override
  Widget build(BuildContext context) {
    if (bundle.setlist.isEmpty) {
      return const _TabEmpty(message: 'セトリはまだ登録されていません。');
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        children: [
          for (final item in bundle.setlist)
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

/// グッズ・戦利品と行った場所（§9）。
class _GoodsView extends StatelessWidget {
  const _GoodsView({required this.bundle});

  final MemoryBundle bundle;

  @override
  Widget build(BuildContext context) {
    if (bundle.goods.isEmpty && bundle.places.isEmpty) {
      return const _TabEmpty(message: 'グッズ・立ち寄り先はまだ登録されていません。');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bundle.goods.isNotEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Column(
              children: [
                for (final item in bundle.goods)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text(item.name),
                    subtitle: item.price == null
                        ? null
                        : Text('¥${item.price} × ${item.quantity}'),
                  ),
              ],
            ),
          ),
        if (bundle.places.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Column(
              children: [
                for (final place in bundle.places)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      place.category == 'food'
                          ? Icons.restaurant_outlined
                          : Icons.place_outlined,
                    ),
                    title: Text(place.name),
                    subtitle: place.memo == null ? null : Text(place.memo!),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// MC・当日メモ / 座席・見え方 / タグ（§9）。
class _NotesView extends StatelessWidget {
  const _NotesView({required this.bundle});

  final MemoryBundle bundle;

  @override
  Widget build(BuildContext context) {
    final entry = bundle.entry;
    final hasMc = entry?.mcNotes.isNotEmpty ?? false;
    final hasSeat = entry?.seatView.isNotEmpty ?? false;
    final tags = entry?.tags ?? const <String>[];
    if (!hasMc && !hasSeat && tags.isEmpty) {
      return const _TabEmpty(message: 'メモはまだありません。');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasMc) _NoteCard(title: 'MC・当日メモ', body: entry!.mcNotes),
        if (hasSeat) ...[
          const SizedBox(height: AppSpace.md),
          _NoteCard(title: '座席・見え方', body: entry!.seatView),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            children: [for (final tag in tags) Chip(label: Text(tag))],
          ),
        ],
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

class _TabEmpty extends StatelessWidget {
  const _TabEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppTokens.of(context).textSecondary),
      ),
    );
  }
}
