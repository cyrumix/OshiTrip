import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/features/itinerary/application/route_recalculation_controller.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/routes_gateway.dart';

/// 呼び出し回数・引数を記録するfakeゲートウェイ（費用制御・single-flightの検証用）。
class _SpyGateway implements RoutesGateway {
  int callCount = 0;
  final List<Completer<Result<RouteLiveResult>>> _pending = [];
  Result<RouteLiveResult> Function()? respondWith;

  @override
  Future<Result<RouteLiveResult>> computeRoute(RouteLiveRequest request) {
    callCount++;
    final completer = Completer<Result<RouteLiveResult>>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext(Result<RouteLiveResult> result) {
    _pending.removeAt(0).complete(result);
  }
}

RouteLiveRequest _request({
  ItineraryTravelMode mode = ItineraryTravelMode.walking,
}) =>
    RouteLiveRequest(
      origin: const RouteEndpoint(latitude: 1, longitude: 2),
      destination: const RouteEndpoint(latitude: 3, longitude: 4),
      travelMode: mode,
      representativeDepartureUtc: DateTime.utc(2026, 7, 9),
    );

void main() {
  group('プレミアムゲート（クライアント側早期ガード）', () {
    test('非プレミアムはゲートウェイを呼ばず型付き拒否を返す', () async {
      final gateway = _SpyGateway();
      final controller = RouteRecalculationController(gateway: gateway);
      final result = await controller.recalculate(
        request: _request(),
        isPremium: false,
        fingerprint: 'fp-1',
      );
      expect(gateway.callCount, 0);
      expect(result.isOk, isFalse);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('プレミアムはゲートウェイを呼ぶ', () async {
      final gateway = _SpyGateway();
      final controller = RouteRecalculationController(gateway: gateway);
      final future = controller.recalculate(
        request: _request(),
        isPremium: true,
        fingerprint: 'fp-1',
      );
      expect(gateway.callCount, 1);
      gateway.completeNext(
        Ok(
          RouteLiveResult(
            durationMinutes: 10,
            distanceMeters: 800,
            requestedAt: DateTime.utc(2026, 7, 9),
          ),
        ),
      );
      final result = await future;
      expect(result.isOk, isTrue);
    });
  });

  group('single-flight（同一fingerprintの重複呼び出しを1回にまとめる）', () {
    test('同一fingerprintの同時呼び出しはゲートウェイを1回しか呼ばない', () async {
      final gateway = _SpyGateway();
      final controller = RouteRecalculationController(gateway: gateway);
      final f1 = controller.recalculate(
        request: _request(),
        isPremium: true,
        fingerprint: 'fp-same',
      );
      final f2 = controller.recalculate(
        request: _request(),
        isPremium: true,
        fingerprint: 'fp-same',
      );
      expect(gateway.callCount, 1); // 2回目はin-flightのFutureを共有
      expect(controller.inFlightFingerprints, {'fp-same'});
      gateway.completeNext(
        Ok(
          RouteLiveResult(
            durationMinutes: 5,
            distanceMeters: 400,
            requestedAt: DateTime.utc(2026, 7, 9),
          ),
        ),
      );
      final r1 = await f1;
      final r2 = await f2;
      expect(r1.isOk, isTrue);
      expect(r2.isOk, isTrue);
      // 完了後はin-flightから除去され、次回呼び出しは新規リクエストになる。
      expect(controller.inFlightFingerprints, isEmpty);
    });

    test('異なるfingerprintは別々にゲートウェイを呼ぶ', () async {
      final gateway = _SpyGateway();
      final controller = RouteRecalculationController(gateway: gateway);
      unawaited(
        controller.recalculate(
          request: _request(),
          isPremium: true,
          fingerprint: 'fp-a',
        ),
      );
      unawaited(
        controller.recalculate(
          request: _request(mode: ItineraryTravelMode.transit),
          isPremium: true,
          fingerprint: 'fp-b',
        ),
      );
      expect(gateway.callCount, 2);
      expect(controller.inFlightFingerprints, {'fp-a', 'fp-b'});
    });

    test('完了後に同一fingerprintを再度呼ぶと新規にゲートウェイを呼ぶ', () async {
      final gateway = _SpyGateway();
      final controller = RouteRecalculationController(gateway: gateway);
      final f1 = controller.recalculate(
        request: _request(),
        isPremium: true,
        fingerprint: 'fp-1',
      );
      gateway.completeNext(
        Ok(
          RouteLiveResult(
            durationMinutes: 1,
            distanceMeters: 1,
            requestedAt: DateTime.utc(2026, 7, 9),
          ),
        ),
      );
      await f1;
      unawaited(
        controller.recalculate(
          request: _request(),
          isPremium: true,
          fingerprint: 'fp-1',
        ),
      );
      expect(gateway.callCount, 2);
    });
  });

  group('明示操作からのみ呼ばれる（初期表示・並び替えだけでは呼ばない）', () {
    test('recalculateを一度も呼ばなければゲートウェイは0回', () {
      final gateway = _SpyGateway();
      RouteRecalculationController(gateway: gateway);
      // 生成しただけ・何もしない = 初期表示・未計算区間表示相当。
      expect(gateway.callCount, 0);
    });
  });
}
