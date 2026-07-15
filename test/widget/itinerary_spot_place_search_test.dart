import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/features/itinerary/application/itinerary_providers.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/places_gateway.dart';
import 'package:oshi_trip/features/itinerary/presentation/itinerary_editors.dart';

import '../helpers/fixtures.dart';

/// スポットの施設名欄（Google候補＋手入力の一体型UI, 修正3/修正5）。
///
/// - Google未設定/無効でも手入力できる（候補が出ず、そのまま入力欄として動く）。
/// - Google候補を選ぶと、施設名・住所が入力欄へ反映され、Place ID が内部保持
///   される（帰属表示で確認）。
class _FakePlacesGateway implements PlacesGateway {
  int autocompleteCalls = 0;
  int detailsCalls = 0;

  @override
  Future<Result<List<PlaceSuggestion>>> autocomplete({
    required String input,
    required PlacesSessionToken sessionToken,
    PlacesLocationBias? bias,
  }) async {
    autocompleteCalls++;
    return const Ok([
      PlaceSuggestion(
        placeId: 'ChIJ_test',
        primaryText: '東京タワー',
        secondaryText: '東京都港区',
      ),
    ]);
  }

  @override
  Future<Result<PlaceDetails>> placeDetails({
    required String placeId,
    required PlacesSessionToken sessionToken,
  }) async {
    detailsCalls++;
    return const Ok(
      PlaceDetails(
        placeId: 'ChIJ_test',
        displayName: '東京タワー',
        formattedAddress: '東京都港区芝公園4-2-8',
      ),
    );
  }
}

const _placesEnabledEnv = AppEnv(
  flavor: Flavor.development,
  supabaseUrl: 'https://test.supabase.co',
  supabaseAnonKey: 'test-anon-key',
  logLevelName: 'debug',
  googleMapsEnabled: true,
);

const _placesDisabledEnv = AppEnv(
  flavor: Flavor.development,
  supabaseUrl: '',
  supabaseAnonKey: '',
  logLevelName: 'debug',
);

Future<void> _pumpEditor(
  WidgetTester tester, {
  required AppEnv env,
  PlacesGateway? gateway,
  SpotEditTarget? existing,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        envProvider.overrideWithValue(env),
        if (gateway != null) placesGatewayProvider.overrideWithValue(gateway),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showItinerarySpotEditor(
                  context,
                  ref,
                  planId: 'plan-1',
                  ownerId: 'demo-user-1',
                  existing: existing,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Google未設定でも施設名を手入力できる（候補は出ない）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpEditor(tester, env: _placesDisabledEnv);

    expect(find.widgetWithText(TextField, '施設名 *'), findsOneWidget);
    expect(find.textContaining('そのまま手入力できます'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, '手入力スポット');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 候補は一切出ない（Places無効）。手入力はそのまま保持される。
    expect(find.byKey(const Key('place_suggestion_ChIJ_test')), findsNothing);
    final nameField =
        tester.widget<TextField>(find.widgetWithText(TextField, '施設名 *'));
    expect(nameField.controller!.text, '手入力スポット');
  });

  testWidgets('住所欄に「共有時は規定で非公開」等の不要な説明文を出さない（item 3）', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpEditor(tester, env: _placesDisabledEnv);

    // 住所欄は存在するが、非公開扱いの説明文は表示しない。
    expect(find.widgetWithText(TextField, '住所'), findsOneWidget);
    expect(find.textContaining('非公開'), findsNothing);
    expect(find.textContaining('共有時'), findsNothing);
  });

  testWidgets('既存スポットを開いても住所をGoogleで自動再取得・上書きしない（ja/JP対応前の保存値を尊重）',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gateway = _FakePlacesGateway();
    // ja/JP対応前に保存された想定の既存スポット（Google由来のPlace ID付き）。
    final existing = SpotEditTarget(
      spot: makeItinerarySpot(
        name: '道玄坂',
        address: '東京都渋谷区道玄坂',
        googlePlaceId: 'ChIJ_existing',
      ),
      entry: makeItineraryEntry(
        id: 'entry-1',
        kind: ItineraryEntryKind.spot,
        spotId: 'spot-1',
      ),
      links: const [],
    );

    await _pumpEditor(
      tester,
      env: _placesEnabledEnv,
      gateway: gateway,
      existing: existing,
    );

    // 開いただけでは Google を一切呼ばない（自動再取得しない）。
    expect(gateway.autocompleteCalls, 0);
    expect(gateway.detailsCalls, 0);

    // 保存済みの住所（日本語）がそのまま保持され、勝手に上書きされない。
    final addressField =
        tester.widget<TextField>(find.widgetWithText(TextField, '住所'));
    expect(addressField.controller!.text, '東京都渋谷区道玄坂');
    // Google由来の英語住所へ差し替わっていないこと。
    expect(find.textContaining('Japan'), findsNothing);
  });

  testWidgets('Google候補を選ぶと施設名・住所が反映され帰属が表示される', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpEditor(
      tester,
      env: _placesEnabledEnv,
      gateway: _FakePlacesGateway(),
    );

    // 3文字以上を入力 → debounce 後に候補が出る。
    await tester.enterText(find.byType(TextField).first, '東京タワー');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    final suggestion = find.byKey(const Key('place_suggestion_ChIJ_test'));
    expect(suggestion, findsOneWidget);

    await tester.tap(suggestion);
    await tester.pumpAndSettle();

    // 施設名・住所が入力欄へ反映される（ラベルは InputDecoration 側なので
    // controller の値が変わっても widgetWithText で引ける）。
    final nameField =
        tester.widget<TextField>(find.widgetWithText(TextField, '施設名 *'));
    expect(nameField.controller!.text, '東京タワー');
    final addressField =
        tester.widget<TextField>(find.widgetWithText(TextField, '住所'));
    expect(addressField.controller!.text, '東京都港区芝公園4-2-8');

    // Place ID を内部保持したことを帰属表示で確認する。
    expect(find.textContaining('Google の候補から選択しました'), findsOneWidget);

    // 候補を選んだ後は候補リストが閉じる。
    expect(find.byKey(const Key('place_suggestion_ChIJ_test')), findsNothing);
  });
}
