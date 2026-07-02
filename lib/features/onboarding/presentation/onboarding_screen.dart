import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/tutorial_controller.dart';

/// 初回チュートリアル（最大4画面・スキップ可、§4.1）。
///
/// 目的は機能説明ではなく、最初の現場登録へ迷わず到達させること。
/// OS通知許可はここでは要求しない。
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (
      icon: Icons.event_note,
      title: '現場を、ひとつにまとめる',
      body: 'チケット・交通・宿泊・持ち物。\n1公演分の準備をひとつの「現場」にまとめて管理できます。',
    ),
    (
      icon: Icons.timeline,
      title: '準備 → 当日 → 思い出',
      body: '公演前は準備リスト、当日は必要情報をすぐ確認、\n終わったらそのまま思い出として残ります。',
    ),
    (
      icon: Icons.lock_outline,
      title: '通知とプライバシー',
      body: '座席やチケットなどの情報は非公開が基本です。\n通知は必要になったタイミングで設定できます。',
    ),
    (
      icon: Icons.favorite,
      title: 'さっそく始めましょう',
      body: '最初の現場を登録すると、\n残り日数とやることが自動で整理されます。',
    ),
  ];

  Future<void> _finish() async {
    await ref.read(tutorialDoneProvider.notifier).complete();
    // 完了後の遷移は router の redirect（未認証→ログイン）が担う。
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'スキップ',
                    semanticsLabel: 'チュートリアルをスキップ',
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.icon,
                          size: 96,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.body,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLast
                      ? _finish
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                  child: Text(
                    isLast ? '最初の現場を登録する' : '次へ',
                    semanticsLabel:
                        isLast ? 'チュートリアルを完了して最初の現場登録へ進む' : '次のページへ',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
