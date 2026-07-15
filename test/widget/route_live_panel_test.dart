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
import 'package:oshi_trip/features/itinerary/domain/itinerary_repository.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_validation.dart';
import 'package:oshi_trip/features/itinerary/domain/routes_gateway.dart';
import 'package:oshi_trip/features/itinerary/presentation/itinerary_import_and_leg.dart';
import 'package:oshi_trip/features/itinerary/presentation/route_live_panel.dart';

import '../helpers/pump_screen.dart';

/// 呼び出し回数を記録し、任意の結果を返すfakeゲートウェイ。最後のリクエストも記録
/// して「最新の経路」が現在時刻ベースか（item 6）を検証できるようにする。
class _FakeGateway implements RoutesGateway {
  _FakeGateway(this._respond);
  final Result<RouteLiveResult> Function() _respond;
  int callCount = 0;
  RouteLiveRequest? lastRequest;

  @override
  Future<Result<RouteLiveResult>> computeRoute(RouteLiveRequest request) {
    callCount++;
    lastRequest = request;
    return Future.value(_respond());
  }
}

/// upsertLeg だけを記録する fake（item 5: 保存された leg の内容を検証する）。
/// パネル単体の描画では他メソッドは呼ばれないため noSuchMethod で満たす。
class _RecordingRepo implements ItineraryRepository {
  ItineraryLeg? saved;

  @override
  Future<Result<void>> upsertLeg(ItineraryLeg leg) async {
    saved = leg;
    return const Ok(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 移動区間カードの経路パネル（item 4/5/6/7）のUI相互作用。
/// - 初期表示だけでは Google を呼ばない・保存済み概算は非プレミアムでも見える
/// - 「経路を確認」でアプリ内取得し、乗換タイムライン（発着時刻・徒歩合計）と
///   帰属を表示する。運賃は通常UIに出さない。leg へ自動保存しない（D-215）
/// - 「この経路を保存」で所要・距離だけを leg に保存する（明示変換, D-180準拠）
/// - 「最新の経路」は現在時刻ベースで取得する（範囲外の予定でも取得できる）
void main() {
  final clock = FixedClock(DateTime.utc(2026, 7, 9, 12));

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

  ItineraryLeg legWith({DateTime? departureAt}) => ItineraryLeg(
        id: 'leg-1',
        planId: 'plan-1',
        ownerId: 'user-1',
        originEntryId: 'e1',
        destinationEntryId: 'e2',
        travelMode: ItineraryTravelMode.transit,
        departureAt: departureAt,
        durationMinutes: 20,
        distanceMeters: 3000,
        createdAt: DateTime.utc(2026, 7, 1),
        updatedAt: DateTime.utc(2026, 7, 1),
      );

  Future<ProviderContainer> pumpPanel(
    WidgetTester tester, {
    required RoutesGateway gateway,
    bool isPremium = true,
    ItineraryLeg? existingLeg,
    String? planId,
    ItineraryEntryOption originOption = origin,
    ItineraryRepository? repo,
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
        if (repo != null) itineraryRepositoryProvider.overrideWithValue(repo),
      ],
      child: Scaffold(
        body: SingleChildScrollView(
          child: RouteLivePanel(
            origin: originOption,
            destination: destination,
            travelMode: ItineraryTravelMode.transit,
            existingLeg: existingLeg,
            planId: planId,
          ),
        ),
      ),
    );
  }

  RouteLiveResult sampleResult() => RouteLiveResult(
        durationMinutes: 15,
        distanceMeters: 2000,
        walkMinutes: 6,
        fareText: '¥180',
        transitSteps: const [
          RouteLiveTransitStep(
            lineName: 'JR山手線',
            lineNameShort: '山手線',
            headsign: '渋谷',
            departureStopName: '新宿駅',
            arrivalStopName: '渋谷駅',
            departureTime: '10:30',
            arrivalTime: '10:45',
          ),
        ],
        requestedAt: DateTime.utc(2026, 7, 9, 12),
      );

  testWidgets('ルータブル端点が無ければ「経路を確認」は出ない・Googleを呼ばない', (tester) async {
    final gateway = _FakeGateway(() => const Err(UnavailableFailure()));
    // 出発端点に spotId/座標が無い（transport参照など）。名前はあるので Google Maps
    // 導線だけは出るが、アプリ内取得ボタンは出ない。
    await pumpPanel(
      tester,
      gateway: gateway,
      originOption: const ItineraryEntryOption(id: 'e1', label: '交通(参照)'),
    );
    expect(find.byKey(const Key('route_check_button')), findsNothing);
    expect(find.byKey(const Key('route_latest_button')), findsNothing);
    expect(gateway.callCount, 0);
  });

  testWidgets('初期表示ではGoogleを呼ばない。保存済み概算は非プレミアムでも見える', (tester) async {
    final gateway = _FakeGateway(() => const Err(UnavailableFailure()));
    await pumpPanel(
      tester,
      gateway: gateway,
      isPremium: false,
      existingLeg: legWith(),
    );

    expect(gateway.callCount, 0);
    expect(find.byKey(const Key('route_saved_estimate')), findsOneWidget);
    expect(find.textContaining('20分'), findsOneWidget);
  });

  testWidgets('「経路を確認」でアプリ内取得し、乗換タイムラインと帰属を表示。運賃は出さない・自動保存しない', (tester) async {
    final gateway = _FakeGateway(() => Ok(sampleResult()));
    final container = await pumpPanel(
      tester,
      gateway: gateway,
      existingLeg: legWith(),
    );

    expect(gateway.callCount, 0);
    await tester.tap(find.byKey(const Key('route_check_button')));
    await tester.pump(); // ローディング
    expect(gateway.callCount, 1);
    expect(find.byKey(const Key('route_live_loading')), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('route_live_result')), findsOneWidget);
    expect(find.textContaining('15分'), findsOneWidget);
    expect(find.textContaining('徒歩 合計6分'), findsOneWidget); // 徒歩合計（item 4）
    expect(find.textContaining('10:30'), findsOneWidget); // 発時刻
    expect(find.textContaining('10:45'), findsOneWidget); // 着時刻
    expect(find.textContaining('新宿駅'), findsOneWidget);
    expect(find.textContaining('¥180'), findsNothing); // 運賃は通常UIに出さない
    expect(find.text('Google Maps'), findsOneWidget); // 帰属表示

    // Googleライブ結果は ItineraryLeg（永続entity）へ自動書き込みしない（D-215）。
    final db = container.read(databaseProvider);
    expect(await db.select(db.itineraryLegs).get(), isEmpty);
  });

  testWidgets('「この経路を保存」で所要・距離だけを leg に保存する（明示変換・D-180準拠, item 5）',
      (tester) async {
    final gateway = _FakeGateway(() => Ok(sampleResult()));
    final repo = _RecordingRepo();
    await pumpPanel(
      tester,
      gateway: gateway,
      existingLeg: legWith(),
      planId: 'plan-1',
      repo: repo,
    );

    await tester.tap(find.byKey(const Key('route_check_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('route_save_button')));
    await tester.pumpAndSettle();

    final saved = repo.saved;
    expect(saved, isNotNull);
    expect(saved!.durationMinutes, 15); // 取得値が保存される
    expect(saved.distanceMeters, 2000);
    // Googleライブの痕跡（source/fetchedAt/cacheKey/polyline）を持たず、
    // 保存境界（D-180）を通過する形にする。
    expect(validateItineraryLegPhase1Persistable(saved), isNull);
    expect(find.text('所要・距離を保存しました'), findsOneWidget);
  });

  testWidgets('「最新の経路」は現在時刻ベース。範囲外の予定でも取得できる（item 6）', (tester) async {
    final gateway = _FakeGateway(() => Ok(sampleResult()));
    // 出発が未来100日超（transit範囲外）の区間。
    await pumpPanel(
      tester,
      gateway: gateway,
      existingLeg: legWith(departureAt: DateTime.utc(2027, 1, 1)),
    );

    // 「経路を確認」は予定時刻ベース → 範囲外で案内を出し、Googleを呼ばない。
    await tester.tap(find.byKey(const Key('route_check_button')));
    await tester.pumpAndSettle();
    expect(gateway.callCount, 0);
    expect(find.byKey(const Key('route_range_notice')), findsOneWidget);

    // 「最新の経路」は現在時刻ベース → 範囲内なので取得できる。
    await tester.tap(find.byKey(const Key('route_latest_button')));
    await tester.pumpAndSettle();
    expect(gateway.callCount, 1);
    expect(find.byKey(const Key('route_live_result')), findsOneWidget);
    // 代表出発は現在時刻（2026-07-09T12:00Z）近傍で、予定(2027-01-01)ではない。
    final reqUtc = gateway.lastRequest!.representativeDepartureUtc;
    expect(reqUtc.year, 2026);
    expect(reqUtc.month, 7);
  });

  testWidgets('非プレミアムでも「経路を確認」でGatewayが呼ばれ結果を表示（プレミアム限定文言なし, D-232）',
      (tester) async {
    final gateway = _FakeGateway(() => Ok(sampleResult()));
    await pumpPanel(
      tester,
      gateway: gateway,
      isPremium: false,
      existingLeg: legWith(),
    );

    await tester.tap(find.byKey(const Key('route_check_button')));
    await tester.pumpAndSettle();

    // 現仕様では非プレミアムでもアプリ内取得できる（Gatewayが呼ばれる）。
    expect(gateway.callCount, 1);
    expect(find.byKey(const Key('route_live_result')), findsOneWidget);
    expect(find.byKey(const Key('route_live_error')), findsNothing);
    // 「プレミアム限定」文言を通常UIに出さない。
    expect(find.textContaining('プレミアム'), findsNothing);
  });

  testWidgets('非プレミアムでも「最新の経路」でGatewayが呼ばれる（D-232）', (tester) async {
    final gateway = _FakeGateway(() => Ok(sampleResult()));
    await pumpPanel(
      tester,
      gateway: gateway,
      isPremium: false,
      existingLeg: legWith(),
    );

    await tester.tap(find.byKey(const Key('route_latest_button')));
    await tester.pumpAndSettle();

    expect(gateway.callCount, 1);
    expect(find.byKey(const Key('route_live_result')), findsOneWidget);
    expect(find.textContaining('プレミアム'), findsNothing);
  });

  testWidgets('APIエラー・欠落フィールドでもクラッシュしない', (tester) async {
    final gateway = _FakeGateway(
      () => const Err(NetworkFailure(message: '通信に失敗しました')),
    );
    await pumpPanel(tester, gateway: gateway, existingLeg: legWith());

    await tester.tap(find.byKey(const Key('route_check_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('route_live_error')), findsOneWidget);
    expect(find.text('通信に失敗しました'), findsOneWidget);
  });
}
