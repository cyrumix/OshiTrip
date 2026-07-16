import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_system/design_system.dart';
import '../../../core/error/failure.dart';
import '../../genba/application/genba_actions_controller.dart';
import '../../genba/application/genba_providers.dart';
import '../../genba/domain/genba.dart';
import '../application/memory_controllers.dart';
import 'memory_edit_widgets.dart';

/// 終演直後の「おつかれさま」もぎり導線（design-spec §9・D-252/M4）。
///
/// 現場が終わった直後、3ステップで軽く記録を促す:
///   ① 参戦した？（attended を設定）→ ② 写真を選ぶ（複数）→ ③ ひとこと感想
/// どのステップもスキップでき、完了すると半券がコレクションに加わる。
Future<void> showAfterEventSheet(
  BuildContext context, {
  required String genbaId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AfterEventSheet(genbaId: genbaId),
  );
}

class _AfterEventSheet extends ConsumerStatefulWidget {
  const _AfterEventSheet({required this.genbaId});

  final String genbaId;

  @override
  ConsumerState<_AfterEventSheet> createState() => _AfterEventSheetState();
}

class _AfterEventSheetState extends ConsumerState<_AfterEventSheet> {
  static const _stepCount = 3;
  int _step = 0;
  int _addedPhotos = 0;
  final _impression = TextEditingController();

  @override
  void dispose() {
    _impression.dispose();
    super.dispose();
  }

  MemoryEditController get _controller =>
      ref.read(memoryEditControllerProvider(widget.genbaId).notifier);

  void _showFailure(Object? failure) {
    if (failure == null || !mounted) return;
    final message = failure is Failure ? failure.message : '操作に失敗しました';
    _showMessage(message);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _next() {
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _finish() {
    // pop 後に破棄済み context を参照しないよう、messenger を先に取得する（レビュー是正）。
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('思い出に追加しました')),
    );
  }

  Future<void> _setAttendance(AttendanceStatus status) async {
    // loading/error/未取得のときは attendance を更新せず進めない（§15・レビュー是正）。
    final async = ref.read(genbaByIdProvider(widget.genbaId));
    final genba = async.valueOrNull?.genba;
    if (genba == null) {
      _showMessage(
        async.isLoading
            ? '現場を読み込み中です。少し待ってお試しください。'
            : async.hasError
                ? '現場を読み込めませんでした。'
                : '現場が見つかりませんでした。',
      );
      return;
    }
    final failure = await ref
        .read(genbaActionsControllerProvider(widget.genbaId).notifier)
        .setAttendanceStatus(genba, status);
    if (!mounted) return;
    // 成功したときだけ次へ進む（attended はユーザーの明示操作の成功時のみ設定）。
    if (failure != null) {
      _showFailure(failure);
      return;
    }
    _next();
  }

  Future<void> _addPhotos() async {
    // 例外安全な共通ヘルパーで複数選択（権限・OS例外を捕捉, §15, レビュー是正）。
    final result = await pickPhotoPaths();
    // 選択中にシートが閉じられた場合、破棄済み State から ref.read しない。
    if (!mounted) return;
    if (result.outcome == PhotoPickOutcome.canceled) return;
    if (result.outcome == PhotoPickOutcome.failed) {
      _showMessage('写真を選択できませんでした');
      return;
    }
    var added = 0;
    for (final path in result.paths) {
      if (!mounted) return;
      final failure = await _controller.addPhoto(path);
      if (!mounted) return;
      if (failure != null) {
        _showFailure(failure);
        break;
      }
      added++;
    }
    if (mounted) setState(() => _addedPhotos += added);
  }

  @override
  Widget build(BuildContext context) {
    // 感想の自動保存を有効化。
    ref.watch(memoryEditControllerProvider(widget.genbaId));
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            0,
            AppSpace.lg,
            AppSpace.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    'おつかれさま！',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${_step + 1}/$_stepCount',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: tokens.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              _stepBody(theme),
              const SizedBox(height: AppSpace.lg),
              _navRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody(ThemeData theme) {
    return switch (_step) {
      0 => _attendanceStep(theme),
      1 => _photoStep(theme),
      _ => _impressionStep(theme),
    };
  }

  Widget _attendanceStep(ThemeData theme) {
    final current =
        ref.watch(genbaByIdProvider(widget.genbaId)).valueOrNull?.genba;
    final status = current?.attendanceStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('参戦しましたか？', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpace.md),
        _ChoiceButton(
          icon: Icons.emoji_events_outlined,
          label: '参戦した',
          selected: status == AttendanceStatus.attended,
          onTap: () => _setAttendance(AttendanceStatus.attended),
        ),
        const SizedBox(height: AppSpace.sm),
        _ChoiceButton(
          icon: Icons.event_busy_outlined,
          label: '行けなかった',
          selected: status == AttendanceStatus.notAttended,
          onTap: () => _setAttendance(AttendanceStatus.notAttended),
        ),
      ],
    );
  }

  Widget _photoStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('写真を残しますか？', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpace.sm),
        Text(
          '複数まとめて選べます。あとから追加もできます。',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppTokens.of(context).textSecondary),
        ),
        const SizedBox(height: AppSpace.md),
        OutlinedButton.icon(
          onPressed: _addPhotos,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('写真を選ぶ'),
        ),
        if (_addedPhotos > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: Text(
              '$_addedPhotos枚を追加しました',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
      ],
    );
  }

  Widget _impressionStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('今日のひとこと', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: _impression,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '短いひとことでOK・あとから加筆できます',
          ),
          maxLines: 4,
          minLines: 3,
          onChanged: (v) =>
              _controller.updateEntry((e) => e.copyWith(impression: v)),
        ),
      ],
    );
  }

  Widget _navRow() {
    final isLast = _step == _stepCount - 1;
    return Row(
      children: [
        if (_step > 0) TextButton(onPressed: _back, child: const Text('戻る')),
        const Spacer(),
        if (!isLast) TextButton(onPressed: _next, child: const Text('スキップ')),
        const SizedBox(width: AppSpace.sm),
        FilledButton(
          onPressed: _next,
          child: Text(isLast ? '完了' : '次へ'),
        ),
      ],
    );
  }
}

/// 参戦有無の選択ボタン（選択中は面を強調）。
class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    return Material(
      color: selected ? tokens.primarySoft : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : tokens.divider,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    selected ? theme.colorScheme.primary : tokens.textSecondary,
              ),
              const SizedBox(width: AppSpace.md),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
