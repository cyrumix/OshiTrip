import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/features/itinerary/application/places_search_controller.dart';
import 'package:oshi_trip/features/itinerary/domain/places_gateway.dart';

/// 呼び出しごとの session token を記録し、応答を差し替えできる Fake ゲートウェイ。
class _FakeGateway implements PlacesGateway {
  final List<String> autocompleteTokens = [];
  final List<String> detailsTokens = [];

  /// 各 autocomplete の遅延（stale 検証用）。
  Duration autocompleteDelay = Duration.zero;

  /// Place Details の遅延（二重タップ・中断検証用）。
  Duration detailsDelay = Duration.zero;

  /// 差し替え応答（null なら入力に応じた既定候補1件）。
  Result<List<PlaceSuggestion>>? autocompleteResult;
  Result<PlaceDetails>? detailsResult;

  @override
  Future<Result<List<PlaceSuggestion>>> autocomplete({
    required String input,
    required PlacesSessionToken sessionToken,
    PlacesLocationBias? bias,
  }) async {
    autocompleteTokens.add(sessionToken.value);
    if (autocompleteDelay > Duration.zero) {
      await Future<void>.delayed(autocompleteDelay);
    }
    return autocompleteResult ??
        Ok([PlaceSuggestion(placeId: 'p-$input', primaryText: input)]);
  }

  @override
  Future<Result<PlaceDetails>> placeDetails({
    required String placeId,
    required PlacesSessionToken sessionToken,
  }) async {
    detailsTokens.add(sessionToken.value);
    if (detailsDelay > Duration.zero) {
      await Future<void>.delayed(detailsDelay);
    }
    return detailsResult ?? Ok(PlaceDetails(placeId: placeId));
  }
}

void main() {
  PlacesSearchController make(_FakeGateway gw) {
    var n = 0;
    return PlacesSearchController(
      gateway: gw,
      generateToken: () => 'tok-${++n}',
      debounce: const Duration(milliseconds: 450),
    );
  }

  test('3文字未満は検索しない（tooShort）', () {
    fakeAsync((async) {
      final gw = _FakeGateway();
      final c = make(gw);
      c.onQueryChanged('と');
      c.onQueryChanged('とう');
      async.elapse(const Duration(milliseconds: 600));
      expect(gw.autocompleteTokens, isEmpty);
      expect(c.state.status, PlacesSearchStatus.tooShort);
      c.dispose();
    });
  });

  test('debounce: 連続入力でも最新1回だけ検索する', () {
    fakeAsync((async) {
      final gw = _FakeGateway();
      final c = make(gw);
      c.onQueryChanged('とうk');
      c.onQueryChanged('とうきょ');
      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));
      expect(gw.autocompleteTokens, hasLength(1));
      expect(c.state.status, PlacesSearchStatus.results);
      expect(c.state.query, 'とうきょう');
      c.dispose();
    });
  });

  test('古い応答は破棄し、最新の結果だけ反映する（stale-drop）', () {
    fakeAsync((async) {
      final gw = _FakeGateway()
        ..autocompleteDelay = const Duration(milliseconds: 100);
      final c = make(gw);

      c.onQueryChanged('AAA');
      async.elapse(const Duration(milliseconds: 450)); // A 発火（100ms遅延）
      c.onQueryChanged('BBBB');
      async.elapse(const Duration(milliseconds: 450)); // A 完了→stale, B 発火
      async.elapse(const Duration(milliseconds: 200)); // B 完了

      expect(gw.autocompleteTokens, hasLength(2));
      expect(c.state.query, 'BBBB');
      expect(c.state.suggestions.single.placeId, 'p-BBBB');
      c.dispose();
    });
  });

  test('セッション: autocomplete と placeDetails は同一 token、選択後は再利用しない', () {
    fakeAsync((async) {
      final gw = _FakeGateway();
      final c = make(gw);

      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));
      expect(gw.autocompleteTokens, ['tok-1']);
      expect(c.debugSessionToken, 'tok-1');

      Result<PlaceDetails>? picked;
      c
          .select(const PlaceSuggestion(placeId: 'p1', primaryText: 'x'))
          .then((r) => picked = r);
      async.flushMicrotasks();
      expect(picked!.isOk, isTrue);
      // 同一セッション token で Details。
      expect(gw.detailsTokens, ['tok-1']);
      // セッション完了 → token 破棄。
      expect(c.debugSessionToken, isNull);

      // 次の検索は新しい token（再利用禁止）。
      c.onQueryChanged('おおさか');
      async.elapse(const Duration(milliseconds: 500));
      expect(gw.autocompleteTokens, ['tok-1', 'tok-2']);
      c.dispose();
    });
  });

  test('中断(abandon)でセッション終了、次の検索は新 token', () {
    fakeAsync((async) {
      final gw = _FakeGateway();
      final c = make(gw);

      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));
      expect(c.debugSessionToken, 'tok-1');

      c.abandon();
      expect(c.debugSessionToken, isNull);
      expect(c.state.status, PlacesSearchStatus.idle);

      c.onQueryChanged('おおさか');
      async.elapse(const Duration(milliseconds: 500));
      expect(gw.autocompleteTokens, ['tok-1', 'tok-2']);
      c.dispose();
    });
  });

  test('二重タップ: 2回目は Google を呼ばず OperationInProgressFailure', () {
    fakeAsync((async) {
      final gw = _FakeGateway()
        ..detailsDelay = const Duration(milliseconds: 100);
      final c = make(gw);
      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));

      Result<PlaceDetails>? r1;
      Result<PlaceDetails>? r2;
      const s = PlaceSuggestion(placeId: 'p1', primaryText: 'x');
      c.select(s).then((r) => r1 = r);
      c.select(s).then((r) => r2 = r); // 同期的な2回目
      async.flushMicrotasks();
      // 2回目は即座に型付き失敗（Google 未呼び出し）。
      expect(r2!.failureOrNull, isA<OperationInProgressFailure>());
      async.elapse(const Duration(milliseconds: 150));
      expect(r1!.isOk, isTrue);
      // Place Details は 1 token につき最大1回。
      expect(gw.detailsTokens, ['tok-1']);
      c.dispose();
    });
  });

  test('Details が失敗しても同じ token を再利用しない（次は新 token）', () {
    fakeAsync((async) {
      final gw = _FakeGateway()..detailsResult = const Err(NetworkFailure());
      final c = make(gw);
      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));

      Result<PlaceDetails>? r;
      c
          .select(const PlaceSuggestion(placeId: 'p1', primaryText: 'x'))
          .then((x) => r = x);
      async.flushMicrotasks();
      expect(r!.isOk, isFalse); // Details 失敗
      // 失敗でも token は消費済み（再利用しない）。
      expect(c.debugSessionToken, isNull);

      // 次の検索は新 token。以降の Details も新 token を使う。
      gw.detailsResult = null;
      c.onQueryChanged('おおさか');
      async.elapse(const Duration(milliseconds: 500));
      expect(gw.autocompleteTokens, ['tok-1', 'tok-2']);
      c
          .select(const PlaceSuggestion(placeId: 'p2', primaryText: 'y'))
          .then((_) {});
      async.flushMicrotasks();
      expect(gw.detailsTokens, ['tok-1', 'tok-2']); // tok-1 を再利用しない
      c.dispose();
    });
  });

  test('中断(abandon)後に完了した Details 結果は採用されない', () {
    fakeAsync((async) {
      final gw = _FakeGateway()
        ..detailsDelay = const Duration(milliseconds: 100);
      final c = make(gw);
      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));

      Result<PlaceDetails>? r;
      c
          .select(const PlaceSuggestion(placeId: 'p1', primaryText: 'x'))
          .then((x) => r = x);
      c.abandon(); // 選択の通信中に中断
      async.elapse(const Duration(milliseconds: 150));
      expect(r!.failureOrNull, isA<OperationInProgressFailure>());
      c.dispose();
    });
  });

  test('選択中は isSelecting=true、完了で false', () {
    fakeAsync((async) {
      final gw = _FakeGateway()
        ..detailsDelay = const Duration(milliseconds: 100);
      final c = make(gw);
      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));
      expect(c.state.isSelecting, isFalse);

      c
          .select(const PlaceSuggestion(placeId: 'p1', primaryText: 'x'))
          .then((_) {});
      async.flushMicrotasks();
      expect(c.state.isSelecting, isTrue);
      async.elapse(const Duration(milliseconds: 150));
      expect(c.state.isSelecting, isFalse);
      c.dispose();
    });
  });

  test('セッション未確立での選択は ValidationFailure', () {
    fakeAsync((async) {
      final gw = _FakeGateway();
      final c = make(gw);
      Result<PlaceDetails>? picked;
      c
          .select(const PlaceSuggestion(placeId: 'p1', primaryText: 'x'))
          .then((r) => picked = r);
      async.flushMicrotasks();
      expect(picked!.failureOrNull, isA<ValidationFailure>());
      expect(gw.detailsTokens, isEmpty);
      c.dispose();
    });
  });

  test('利用不可(UnavailableFailure)なら手動フォールバック可能', () {
    fakeAsync((async) {
      final gw = _FakeGateway()
        ..autocompleteResult = const Err(UnavailableFailure());
      final c = make(gw);
      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));
      expect(c.state.status, PlacesSearchStatus.unavailable);
      expect(c.state.canFallbackToManual, isTrue);
      c.dispose();
    });
  });

  test('候補ゼロなら empty＋手動フォールバック可能', () {
    fakeAsync((async) {
      final gw = _FakeGateway()..autocompleteResult = const Ok([]);
      final c = make(gw);
      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));
      expect(c.state.status, PlacesSearchStatus.empty);
      expect(c.state.canFallbackToManual, isTrue);
      c.dispose();
    });
  });

  test('通信失敗(error)でも手動フォールバック可能', () {
    fakeAsync((async) {
      final gw = _FakeGateway()
        ..autocompleteResult = const Err(NetworkFailure());
      final c = make(gw);
      c.onQueryChanged('とうきょう');
      async.elapse(const Duration(milliseconds: 500));
      expect(c.state.status, PlacesSearchStatus.error);
      expect(c.state.canFallbackToManual, isTrue);
      c.dispose();
    });
  });
}
