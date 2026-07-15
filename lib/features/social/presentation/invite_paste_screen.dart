import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system/design_system.dart';
import '../../sharing/domain/genba_invite.dart';

/// 招待リンクを貼り付けて参加する画面（Deep Link 代替導線, 追加要件 §8）。
///
/// `https://oshitrip.app/invite/{token}` を貼るか、token を直接入力して参加する。
/// 最終的には Deep Link で直接この参加フローへ入る（Phase 5）。
class InvitePasteScreen extends StatefulWidget {
  const InvitePasteScreen({super.key});

  @override
  State<InvitePasteScreen> createState() => _InvitePasteScreenState();
}

class _InvitePasteScreenState extends State<InvitePasteScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final token = inviteTokenFromUrl(_controller.text);
    if (token == null) {
      setState(() => _error = '招待リンクまたはコードを正しく入力してください');
      return;
    }
    setState(() => _error = null);
    context.push('/invite/$token');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: '招待リンクで参加',
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          Text(
            'LINEやDMで受け取った招待リンクを貼り付けてください',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 2,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: '招待リンク / コード',
              hintText: 'https://oshitrip.app/invite/...',
              errorText: _error,
              prefixIcon: const Icon(Icons.link_outlined),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton(onPressed: _submit, child: const Text('参加へ進む')),
        ],
      ),
    );
  }
}
