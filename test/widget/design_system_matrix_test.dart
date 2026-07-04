import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/design_system/design_system.dart';
import 'package:oshi_trip/app/theme/app_theme.dart';

import '../helpers/pump_screen.dart';

/// レスポンシブ・テーマ・文字拡大・推しカラーのマトリクス検証
/// （design-spec §14/§15: 360dp/430dp × light/dark × textScale 2.0 ×
/// 推しカラー8色以上で、オーバーフローせず主要情報が欠落しない）。
///
/// RenderFlex overflow はテストフレームワークが例外として検出するため、
/// 「pump が成功し主要テキストが存在する」ことが合否基準になる。
void main() {
  Widget sampleSurface(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeroEventCard(
          title: '全国ツアー final ～夜明け前の遠征ノート～',
          artistName: 'とても長い名前の推しグループ',
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
        const SizedBox(height: 12),
        EventListCard(
          title: '長い公演名でも折返しや省略で欠落しないことを確認する公演',
          subtitle: '推しグループ',
          dateLabel: '2026/9/15・18:00開演',
          venue: 'さいたまスーパーアリーナ',
          daysUntil: 74,
          accentColor: accent,
        ),
        const SizedBox(height: 12),
        PhotoMemoryCard(
          title: '春の単独公演',
          dateLabel: '2026/6/1',
          venue: 'Zepp Haneda',
          photoCount: 18,
          setlistCount: 12,
          hasImpression: true,
          attendedLabel: '参戦済み',
          accentColor: accent,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OshiAvatar(name: '推し', ringColor: accent, selected: true),
            const SizedBox(width: 8),
            Expanded(
              child: SegmentTabs(
                tabs: const ['すべて', '参戦済み', 'お気に入り'],
                selectedIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  for (final dark in [false, true]) {
    for (final width in [360.0, 430.0]) {
      testWidgets(
          '主要コンポーネントが ${dark ? 'dark' : 'light'}/${width.toInt()}dp で欠落しない',
          (tester) async {
        await pumpComponent(
          tester,
          sampleSurface(const Color(0xFFFF5CA8)),
          dark: dark,
          logicalWidth: width,
        );
        expect(find.textContaining('全国ツアー final'), findsOneWidget);
        expect(find.textContaining('29'), findsOneWidget);
        expect(find.text('参戦済み'), findsWidgets);
      });
    }
  }

  testWidgets('文字200%（textScale 2.0）でも主要情報が成立する（§14）', (tester) async {
    await pumpComponent(
      tester,
      sampleSurface(const Color(0xFFFF5CA8)),
      logicalWidth: 360,
      textScale: 2.0,
    );
    expect(find.textContaining('全国ツアー final'), findsOneWidget);
    expect(find.text('春の単独公演'), findsOneWidget);
  });

  testWidgets('推しカラー全プリセット（8色以上）でアクセントが適用できる（§11/§15）', (tester) async {
    expect(oshiColorPresets.length, greaterThanOrEqualTo(8));
    for (final preset in oshiColorPresets) {
      final accent = AppTheme.tryParseHexColor(preset.hex)!;
      await pumpComponent(
        tester,
        Column(
          children: [
            EventListCard(
              title: '公演 ${preset.name}',
              dateLabel: '2026/8/1',
              daysUntil: 3,
              accentColor: accent,
            ),
            OshiAvatar(name: preset.name, ringColor: accent),
          ],
        ),
        logicalWidth: 360,
      );
      expect(find.text('公演 ${preset.name}'), findsOneWidget);
    }
  });
}
