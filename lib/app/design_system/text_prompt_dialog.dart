import 'package:flutter/material.dart';

/// 1行のテキスト入力を受け取る汎用ダイアログ（design-spec 共通コンポーネント）。
///
/// `TextEditingController` はダイアログ自身の State のライフサイクルで
/// 所有・破棄する。`showDialog` の Future 完了＝pop 呼び出し時点であり、退場
/// アニメーション中はまだ TextField が生存しているため、呼び出し元で
/// 即座に dispose すると「disposed 後の Controller 使用」で描画中に例外が出る
/// （`template_manage_screen.dart`・`genba_form_screen.dart` の既存の名前入力
/// ダイアログと同じ構造・同じ理由）。
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  required String labelText,
  String initialText = '',
  String? hintText,
  String confirmLabel = '保存',
  String cancelLabel = 'キャンセル',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextPromptDialog(
      title: title,
      labelText: labelText,
      initialText: initialText,
      hintText: hintText,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.labelText,
    required this.initialText,
    required this.confirmLabel,
    required this.cancelLabel,
    this.hintText,
  });

  final String title;
  final String labelText;
  final String initialText;
  final String? hintText;
  final String confirmLabel;
  final String cancelLabel;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
