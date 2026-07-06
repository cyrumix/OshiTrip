import 'package:flutter/material.dart';

/// 計画タブの編集ボトムシート共通枠（child_editors の _EditorScaffold と同型）。
/// 保存・削除の進行中は保存/削除/閉じる/戻る/ドラッグ終了を無効化して、
/// 未確定のまま閉じられるのを防ぐ（H-07/M-01）。
class ItinerarySheetScaffold extends StatefulWidget {
  const ItinerarySheetScaffold({
    super.key,
    required this.title,
    required this.onSave,
    required this.children,
    this.onDelete,
    this.saveLabel = '保存する',
  });

  final String title;
  final Future<void> Function() onSave;
  final Future<void> Function()? onDelete;
  final List<Widget> children;
  final String saveLabel;

  @override
  State<ItinerarySheetScaffold> createState() => _ItinerarySheetScaffoldState();
}

class _ItinerarySheetScaffoldState extends State<ItinerarySheetScaffold> {
  bool _saving = false;
  bool _deleting = false;
  bool get _busy => _saving || _deleting;

  Future<void> _handleSave() async {
    if (_busy) return;
    setState(() => _saving = true);
    try {
      await widget.onSave();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleDelete() async {
    if (_busy || widget.onDelete == null) return;
    setState(() => _deleting = true);
    try {
      await widget.onDelete!();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (_) => _busy,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        onPressed: _busy ? null : _handleDelete,
                        tooltip: '削除',
                        color: Theme.of(context).colorScheme.error,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    IconButton(
                      onPressed:
                          _busy ? null : () => Navigator.of(context).pop(),
                      tooltip: '閉じる',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: widget.children,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                semanticsLabel: '保存中',
                              ),
                            )
                          : Text(widget.saveLabel),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// シート表示の共通ヘルパ。
Future<void> showItinerarySheet(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: child,
    ),
  );
}

/// enum選択チップ（child_editors の _EnumSelector と同型・独立実装）。
class ItineraryEnumChips<T> extends StatelessWidget {
  const ItineraryEnumChips({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final void Function(T value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(labelOf(value)),
                  selected: value == selected,
                  onSelected: (_) => onChanged(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
