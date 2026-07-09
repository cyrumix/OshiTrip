import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/itinerary/application/routes_providers.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/routes_gateway.dart';
import 'package:oshi_trip/features/itinerary/presentation/itinerary_import_and_leg.dart';
import 'package:oshi_trip/features/itinerary/presentation/route_live_panel.dart';

import '../helpers/pump_screen.dart';

/// 呼び出し回数を記録し、任意の結果を返すfakeゲートウェイ。
class _FakeGateway implements RoutesGateway {
  _FakeGateway(this._respond);
  final Result<RouteLiveResult> Function() _respond;
  int callCount = 0;

  @override
  Future<Result<RouteLiveResult>> computeRoute(RouteLiveRequest request) {
    callCount++;
    return Future.value(_respond());
  }
}

/// 旅程Phase 4: 経路詳細パネルのUI相互作用。保存済み概算のオフライン表示・
/// 初期表示だけではAPIを呼ばないこと・「経路詳細を開く」タップで初めて呼ぶこと・
/// 非プレミアムの抑止表示・欠落フィールドでもクラッシュしないこと・
/// Google帰属表示を検証する。
void main() {
  final clock = FixedClock(DateTime(2026, 7, 9, 12));

  const origin = ItineraryEntryOption(
    id: 'e1',
    label: '出発スポット',
    spotId: 's1',
    latitude: 35.0,
    longitude: 139.0,
  );
  const destination = ItineraryEntryOption(
    id: 'e2',
    label: '到着スポット',
    spotId: 's2',
    latitude: 35.1,
    longitude: 139.1,
  );

  Future<ProviderContainer> pumpPanel(
    WidgetTester tester, {
    required RoutesGateway gateway,
    bool isPremium = true,
    ItineraryLeg? existingLeg,
  }) async {
    final db = await signedInTestDb();
    addTearDown(db.close);
    return pumpScreen(
      tester,
      db: db,
      clock: clock,
      extraOverrides: [
        routesGatewayProvider.overrideWithValue(gateway),
        routesIsPremiumProvider.overrideWith((ref) => Stream.value(isPremium)),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: RouteLivePanel(
            origin: origin,
            destination: destination,
            travelMode: ItineraryTravelMode.transit,
            existingLeg: existingLeg,
          ),
        ),
      ),
    );
  }

  testWidgets('端点に座標が無ければ何も表示しない（スポット↔スポットのみ対象）', (tester) async {
    final gateway = _FakeGateway(
      () => const Err(UnavailableFailure()),
    );
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      extraOverrides: [routesGatewayProvider.overrideWithValue(gateway)],
      child: const Scaffold(
        body: RouteLivePanel(
          origin: ItineraryEntryOption(id: 'e1', label: '交通(参照)'),
          destination: destination,
          travelMode: ItineraryTravelMode.transit,
          existingLeg: null,
        ),
      ),
    );
    expect(find.byKey(const Key('route_detail_toggle')), findsNothing);
    expect(gateway.callCount, 0);
  });

  testWidgets('初期表示だけではGoogleを呼ばない。保存済み概算は非プレミアムでも見える', (tester) async {
    final gateway = _FakeGateway(() => const Err(UnavailableFailure()));
    final leg = ItineraryLeg(
      id: 'leg-1',
      planId: 'plan-1',
      ownerId: 'user-1',
      originEntryId: 'e1',
      destinationEntryId: 'e2',
      travelMode: ItineraryTravelMode.transit,
      durationMinutes: 20,
      distanceMeters: 3000,
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );
    await pumpPanel(
      tester,
      gateway: gateway,
      isPremium: false,
      existingLeg: leg,
    );

    expect(gateway.callCount, 0); // 初期表示だけでは呼ばない
    expect(find.byKey(const Key('route_saved_estimate')), findsOneWidget);
    expect(find.textContaining('20分'), findsOneWidget);
  });

  testWidgets('「経路詳細」を開くと初めてGoogleを呼び、結果と帰属を表示する', (tester) async {
    final gateway = _FakeGateway(
      () => Ok(
        RouteLiveResult(
          durationMinutes: 15,
          distanceMeters: 2000,
          fareText: '¥180',
          transitSteps: const [
            RouteLiveTransitStep(
              lineName: 'JR山手線',
              lineNameShort: '山手線',
              headsign: '渋谷方面',
              departureStopName: '新宿駅',
              arrivalStopName: '渋谷駅',
            ),
          ],
          requestedAt: DateTime.utc(2026, 7, 9, 12),
        ),
      ),
    );
    final container = await pumpPanel(tester, gateway: gateway);

    expect(gateway.callCount, 0);
    await tester.tap(find.byKey(const Key('route_detail_toggle')));
    await tester.pump(); // ローディング表示

    expect(gateway.callCount, 1);
    expect(find.byKey(const Key('route_live_loading')), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('route_live_result')), findsOneWidget);
    expect(find.textContaining('15分'), findsOneWidget);
    expect(find.textContaining('¥180'), findsOneWidget);
    expect(find.textContaining('新宿駅'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget); // 帰属表示
    expect(find.text('最新ルートを更新'), findsOneWidget);

    // Googleライブ結果は ItineraryLeg（永続entity）へ書き込まない（D-215維持）。
    final db = container.read(databaseProvider);
    expect(await db.select(db.itineraryLegs).get(), isEmpty);

    // 再タップでも明示的な更新ボタン経由でのみ再度呼ぶ。
    await tester.tap(find.byKey(const Key('route_refresh_button')));
    await tester.pumpAndSettle();
    expect(gateway.callCount, 2);
  });

  testWidgets('非プレミアムは更新ボタンが無く、Googleを呼ばない', (tester) async {
    final gateway = _FakeGateway(
      () => Ok(
        RouteLiveResult(
          durationMinutes: 1,
          distanceMeters: 1,
          requestedAt: DateTime.utc(2026, 7, 9),
        ),
      ),
    );
    await pumpPanel(tester, gateway: gateway, isPremium: false);

    await tester.tap(find.byKey(const Key('route_detail_toggle')));
    await tester.pumpAndSettle();

    expect(gateway.callCount, 0); // recalculateはコントローラ内でPermissionFailure即返却
    expect(find.textContaining('プレミアム限定'), findsOneWidget);
    expect(find.text('最新ルートを更新'), findsNothing);
  });

  testWidgets('APIエラー・欠落フィールドでもクラッシュしない', (tester) async {
    final gateway = _FakeGateway(
      () => const Err(NetworkFailure(message: '通信に失敗しました')),
    );
    await pumpPanel(tester, gateway: gateway);

    await tester.tap(find.byKey(const Key('route_detail_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('route_live_error')), findsOneWidget);
    expect(find.text('通信に失敗しました'), findsOneWidget);
  });

  testWidgets('公共交通で代表時刻が対応範囲外なら、APIを呼ばず案内を出す（修正5）', (tester) async {
    var callCount = 0;
    final gateway = _FakeGateway(() {
      callCount++;
      return const Err(UnavailableFailure());
    });
    // clock は 2026-07-09。出発が未来100日超（範囲外）の transit 区間。
    final farLeg = ItineraryLeg(
      id: 'leg-far',
      planId: 'plan-1',
      ownerId: 'user-1',
      originEntryId: 'e1',
      destinationEntryId: 'e2',
      travelMode: ItineraryTravelMode.transit,
      departureAt: DateTime.utc(2027, 1, 1), // ~176日後 → 範囲外
      durationMinutes: 20,
      distanceMeters: 3000,
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: DateTime.utc(2026, 7, 1),
    );
    await pumpPanel(tester, gateway: gateway, existingLeg: farLeg);

    await tester.tap(find.byKey(const Key('route_detail_toggle')));
    await tester.pumpAndSettle();

    expect(callCount, 0); // Google Routes を呼ばない
    expect(find.byKey(const Key('route_range_notice')), findsOneWidget);
    // 保存済み概算は引き続き見える。
    expect(find.byKey(const Key('route_saved_estimate')), findsOneWidget);
    expect(find.byKey(const Key('route_live_result')), findsNothing);
  });
}
