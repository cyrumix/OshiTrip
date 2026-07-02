import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../application/auth_controller.dart';

/// ログイン画面。
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
    }
    // 成功時の遷移は router の redirect が行う。
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    final env = ref.watch(envProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (env.isDemoMode)
                  Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'デモモード\nサーバー未設定のため、端末内のみで動作します。'
                        '任意のメールアドレスとパスワード（6文字以上）で開始できます。',
                      ),
                    ),
                  ),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'メールアドレスを入力してください'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'パスワード'),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  validator: (v) => (v == null || v.length < 6)
                      ? 'パスワードは6文字以上で入力してください'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('ログイン', semanticsLabel: 'ログインする'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: busy ? null : () => context.push('/signup'),
                  child: const Text('アカウントを新規登録'),
                ),
                TextButton(
                  onPressed:
                      busy ? null : () => context.push('/password-reset'),
                  child: const Text('パスワードをお忘れですか？'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 新規登録画面。
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final failure = await ref
        .read(authControllerProvider.notifier)
        .signUp(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    // メール確認が必要な設定の場合はセッションが張られないため案内を出す。
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('確認メールを送信しました。メール内のリンクを開いてからログインしてください'),
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'メールアドレスを入力してください'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'パスワード（6文字以上）'),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'パスワードは6文字以上で入力してください'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  decoration: const InputDecoration(labelText: 'パスワード（確認）'),
                  obscureText: true,
                  validator: (v) => v != _password.text ? 'パスワードが一致しません' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : _submit,
                  child: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('登録する', semanticsLabel: 'アカウントを登録する'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// パスワード再設定画面。
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final failure = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure?.message ?? '再設定メールを送信しました。受信メールをご確認ください',
        ),
      ),
    );
    if (failure == null) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('パスワード再設定')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('登録済みのメールアドレスへ再設定用リンクを送信します。'),
              const SizedBox(height: 16),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: busy ? null : _submit,
                child: const Text('送信する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
