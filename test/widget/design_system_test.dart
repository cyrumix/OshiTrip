import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/design_system/design_system.dart';
import 'package:oshi_trip/app/theme/app_theme.dart';

import '../helpers/pump_screen.dart';

/// 共通Design Systemコンポーネントの意味上のWidgetテスト（design-spec §4/§15）。
void main() {
  group('Design Token / AppTheme', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    test('ライト: 基準トークンがデザイン刷新（明るいラベンダー×白カード）の値である', () {
      final theme = AppTheme.light();
      final tokens = theme.extension<AppTokens>()!;
      expect(theme.colorScheme.primary, const Color(0xFF7461E6));
      expect(theme.scaffoldBackgroundColor, const Color(0xFFFAF9FE));
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.onSurface, const Color(0xFF29233E));
      // 白面で AA（4.5:1）以上を満たす値（app_tokens.dart のコメント参照）。
      expect(tokens.textSecondary, const Color(0xFF716B8A));
      expect(tokens.divider, const Color(0xFFEDEAF6));
      expect(tokens.primarySoft, const Color(0xFFEFEBFD));
      // ヒーローの菫グラデーションと暁アクセント。
      expect(tokens.heroGradientStart, const Color(0xFF9180F0));
      expect(tokens.dawn, const Color(0xFFF2A98F));
    });

    test('ライト/ダークとも主要テキストのコントラストが AA 相当（§2/§14）', () {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        final scheme = theme.colorScheme;
        // 本文（onSurface on surface）は 4.5:1 以上。
        expect(
          contrast(scheme.onSurface, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${theme.brightness}: onSurface/surface',
        );
        // 背景上の本文も 4.5:1 以上。
        expect(
          contrast(scheme.onSurface, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
          reason: '${theme.brightness}: onSurface/background',
        );
        // 補足テキストは 4.5:1 以上（12sp未満は使わない前提, §3）。
        final tokens = theme.extension<AppTokens>()!;
        expect(
          contrast(tokens.textSecondary, scheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${theme.brightness}: textSecondary/surface',
        );
        // 主要ボタン（onPrimary on primary）は UIコンポーネント基準 3:1 以上。
        expect(
          contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(3.0),
          reason: '${theme.brightness}: onPrimary/primary',
        );
      }
    });

    test('ダークはライトの単純な色反転ではない（背景が暗色面・文字が明色）', () {
      final dark = AppTheme.dark();
      expect(
        dark.scaffoldBackgroundColor.computeLuminance(),
        lessThan(0.1),
      );
      expect(dark.colorScheme.onSurface.computeLuminance(), greaterThan(0.5));
    });

    test('推しカラープリセットは8色以上あり、すべて解析可能（§11）', () {
      expect(oshiColorPresets.length, greaterThanOrEqualTo(8));
      for (final preset in oshiColorPresets) {
        expect(
          AppTheme.tryParseHexColor(preset.hex),
          isNotNull,
          reason: preset.name,
        );
      }
    });

    test('tryParseHexColor は不正値を null にする（外部データを信頼しない）', () {
      expect(AppTheme.tryParseHexColor(null), isNull);
      expect(AppTheme.tryParseHexColor('red'), isNull);
      expect(AppTheme.tryParseHexColor('#12345'), isNull);
      expect(AppTheme.tryParseHexColor('#GGGGGG'), isNull);
      expect(AppTheme.tryParseHexColor('#7B5CFF'), const Color(0xFF7B5CFF));
      expect(AppTheme.tryParseHexColor('7B5CFF'), const Color(0xFF7B5CFF));
    });
  });

  group('SegmentTabs', () {
    testWidgets('選択状態が Semantics(selected) とピルの塗りで示され、タップで切替できる',
        (tester) async {
      var selected = 0;
      await pumpComponent(
        tester,
        StatefulBuilder(
          builder: (context, setState) => SegmentTabs(
            tabs: const ['すべて', '参戦済み', 'お気に入り'],
            selectedIndex: selected,
            onSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('すべて')),
        matchesSemantics(
          isSelected: true,
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasSelectedState: true,
          label: 'すべて',
        ),
      );
      await tester.tap(find.text('参戦済み'));
      await tester.pump();
      expect(selected, 1);
      // 主要タップ領域 48dp 以上（§3）。
      final size = tester.getSize(
        find.ancestor(
          of: find.text('参戦済み'),
          matching: find.byType(InkWell),
        ),
      );
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('FavoriteButton', () {
    testWidgets('状態が形（塗り/輪郭）とラベルで表現され、48dp以上のタップ領域を持つ', (tester) async {
      var favorite = false;
      await pumpComponent(
        tester,
        StatefulBuilder(
          builder: (context, setState) => FavoriteButton(
            isFavorite: favorite,
            onPressed: () => setState(() => favorite = !favorite),
            subjectLabel: 'テスト公演',
          ),
        ),
      );
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
      expect(find.byTooltip('テスト公演をお気に入りに追加'), findsOneWidget);

      await tester.tap(find.byType(FavoriteButton));
      await tester.pump();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byTooltip('テスト公演をお気に入りから外す'), findsOneWidget);

      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('OshiAvatar', () {
    testWidgets('画像なしはイニシャルへフォールバックし、選択状態を Semantics で伝える', (tester) async {
      await pumpComponent(
        tester,
        const Row(
          children: [
            OshiAvatar(name: '推しメン', ringColor: Color(0xFFFF5CA8)),
            OshiAvatar(name: '最推し', selected: true),
          ],
        ),
      );
      // イニシャル（先頭1文字）フォールバック。
      expect(find.text('推'), findsOneWidget);
      expect(find.text('最'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('最')),
        matchesSemantics(
          label: '最推し',
          isSelected: true,
          hasSelectedState: true,
        ),
      );
    });
  });

  group('CountStat / StatusIconItem', () {
    testWidgets('導出値とラベルを表示し、読み上げ用ラベルを持つ', (tester) async {
      await pumpComponent(
        tester,
        const Row(
          children: [
            Expanded(
              child: CountStat(
                value: 3,
                label: '参戦数',
                semanticsLabel: '参戦数 3件（参加を明示した現場のみ）',
              ),
            ),
            Expanded(
              child: StatusIconItem(
                icon: Icons.train_outlined,
                label: '交通',
                value: '未登録',
                emphasized: true,
              ),
            ),
          ],
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('参戦数'), findsOneWidget);
      expect(
        find.bySemanticsLabel('参戦数 3件（参加を明示した現場のみ）'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('交通: 未登録'), findsOneWidget);
    });
  });

  group('SyncBadge', () {
    testWidgets('各状態がアイコン+文言で示される（色だけに依存しない, §14）', (tester) async {
      await pumpComponent(
        tester,
        const Column(
          children: [
            SyncBadge(status: SyncBadgeStatus.savedLocally),
            SyncBadge(status: SyncBadgeStatus.syncing),
            SyncBadge(status: SyncBadgeStatus.failed),
            SyncBadge(status: SyncBadgeStatus.conflict),
          ],
        ),
      );
      expect(find.text('端末に保存済み'), findsOneWidget);
      expect(find.text('同期中'), findsOneWidget);
      expect(find.text('同期に失敗'), findsOneWidget);
      expect(find.text('競合あり'), findsOneWidget);
    });
  });

  group('EventListCard', () {
    testWidgets('日付・公演名・会場・残日数と推しカラー罫線を表示する', (tester) async {
      await pumpComponent(
        tester,
        const EventListCard(
          title: '夏の単独公演',
          subtitle: '推しグループ',
          dateLabel: '2026/8/1・18:00開演',
          venue: '横浜アリーナ',
          daysUntil: 12,
          accentColor: Color(0xFFFF5CA8),
        ),
      );
      expect(find.text('夏の単独公演'), findsOneWidget);
      expect(find.text('横浜アリーナ'), findsOneWidget);
      expect(find.text('あと12日'), findsOneWidget);
      expect(find.bySemanticsLabel('公演まであと12日'), findsOneWidget);
    });

    testWidgets('過去の現場は「n日前」と表示する', (tester) async {
      await pumpComponent(
        tester,
        const EventListCard(
          title: '過去公演',
          dateLabel: '2026/6/1',
          daysUntil: -3,
          accentColor: Color(0xFF7B5CFF),
        ),
      );
      expect(find.text('3日前'), findsOneWidget);
    });
  });

  group('HeroEventCard', () {
    testWidgets('写真なしでは紫グラデーションで成立し、残日数と4分割状態を表示する', (tester) async {
      await pumpComponent(
        tester,
        const HeroEventCard(
          title: '全国ツアー final',
          artistName: '推しグループ',
          dateLabel: '2026/8/1',
          timeLabel: '開場 17:00 / 開演 18:00',
          venue: '東京ドーム',
          daysUntil: 29,
          statusItems: [
            StatusIconItem(
              icon: Icons.check_box_outlined,
              label: 'Todo',
              value: '残り3',
              onSurface: Colors.white,
            ),
            StatusIconItem(
              icon: Icons.train_outlined,
              label: '交通',
              value: '未登録',
              onSurface: Colors.white,
            ),
            StatusIconItem(
              icon: Icons.hotel_outlined,
              label: '宿泊',
              value: '不要',
              onSurface: Colors.white,
            ),
            StatusIconItem(
              icon: Icons.confirmation_number_outlined,
              label: 'チケット',
              value: '準備OK',
              onSurface: Colors.white,
            ),
          ],
        ),
      );
      // 写真なしでも全要素が成立する（§15: 写真なしでも主要フロー成立）。
      expect(find.text('全国ツアー final'), findsOneWidget);
      // 残日数は Text.rich（'あと 29 日'）として描画される。
      expect(find.textContaining('29'), findsOneWidget);
      expect(find.text('残り3'), findsOneWidget);
      expect(find.text('未登録'), findsOneWidget);
      expect(find.text('不要'), findsOneWidget);
      expect(find.text('準備OK'), findsOneWidget);
    });

    testWidgets('本日は「本日」を最大表示する', (tester) async {
      await pumpComponent(
        tester,
        const HeroEventCard(
          title: '当日公演',
          artistName: 'アーティスト',
          dateLabel: '2026/7/2',
          daysUntil: 0,
        ),
      );
      expect(find.text('本日'), findsOneWidget);
    });
  });

  group('PhotoMemoryCard', () {
    testWidgets('写真なしプレースホルダー・記録件数・参戦済み・お気に入りを表示する', (tester) async {
      var favoriteTapped = false;
      await pumpComponent(
        tester,
        PhotoMemoryCard(
          title: '春の単独公演',
          subtitle: '推しグループ',
          dateLabel: '2026/6/1',
          venue: 'Zepp',
          photoCount: 18,
          setlistCount: 12,
          hasImpression: true,
          attendedLabel: '参戦済み',
          isFavorite: true,
          onFavoriteToggle: () => favoriteTapped = true,
          accentColor: const Color(0xFFFF5CA8),
        ),
      );
      expect(find.text('春の単独公演'), findsOneWidget);
      expect(find.text('参戦済み'), findsOneWidget);
      expect(find.bySemanticsLabel('写真18枚'), findsOneWidget);
      expect(find.bySemanticsLabel('セトリ12曲'), findsOneWidget);
      expect(find.bySemanticsLabel('感想あり'), findsOneWidget);
      // 写真なし → プレースホルダー（権利不明画像は使わない）。
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);

      await tester.tap(find.byType(FavoriteButton));
      expect(favoriteTapped, isTrue);
    });
  });

  group('EmptyState / LoadingSkeleton', () {
    testWidgets('EmptyState は説明と次の1アクションを表示する', (tester) async {
      var tapped = false;
      await pumpComponent(
        tester,
        EmptyState(
          message: 'まだデータがありません',
          description: '説明文',
          actionLabel: '登録する',
          onAction: () => tapped = true,
        ),
      );
      expect(find.text('まだデータがありません'), findsOneWidget);
      await tester.tap(find.text('登録する'));
      expect(tapped, isTrue);
    });

    testWidgets('LoadingSkeleton は Reduce Motion 時に明滅しない（§13/§14）',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: LoadingSkeleton.list()),
          ),
        ),
      );
      await tester.pump();
      // アニメーションが止まっているため pump し続けなくてもフレームが安定する。
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.bySemanticsLabel('読み込み中'), findsOneWidget);
    });
  });

  group('SettingsRow', () {
    testWidgets('項目名・現在値を表示し、危険操作はError色で分離される', (tester) async {
      await pumpComponent(
        tester,
        const Column(
          children: [
            SettingsRow(
              icon: Icons.brightness_6_outlined,
              title: 'テーマ設定',
              value: 'ライト',
            ),
            SettingsRow(
              icon: Icons.delete_forever_outlined,
              title: 'アカウントとデータを削除',
              destructive: true,
            ),
          ],
        ),
      );
      expect(find.text('テーマ設定'), findsOneWidget);
      expect(find.text('ライト'), findsOneWidget);
      final dangerText = tester.widget<Text>(find.text('アカウントとデータを削除'));
      expect(
        dangerText.style?.color,
        AppTheme.light().colorScheme.error,
      );
    });
  });
}
