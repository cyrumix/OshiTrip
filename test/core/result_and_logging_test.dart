import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/logging/app_logger.dart';

void main() {
  group('Result / Failure変換', () {
    test('正常系は Ok を返す', () async {
      final result = await guardResult(() async => 42);
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, 42);
    });

    test('Failure はそのまま Err になる', () async {
      final result = await guardResult<int>(
        () async => throw const ValidationFailure('入力エラー'),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, '入力エラー');
    });

    test('TimeoutException は NetworkFailure へ変換される', () async {
      final result = await guardResult<int>(
        () async => throw TimeoutException('timeout'),
      );
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('未知の例外は UnknownFailure へ変換され原因を保持する', () async {
      final result =
          await guardResult<int>(() async => throw StateError('boom'));
      final failure = result.failureOrNull;
      expect(failure, isA<UnknownFailure>());
      expect(failure?.cause, isA<StateError>());
    });

    test('onError で任意の Failure へ変換できる', () async {
      final result = await guardResult<int>(
        () async => throw StateError('db'),
        onError: (e, _) => StorageFailure(cause: e),
      );
      expect(result.failureOrNull, isA<StorageFailure>());
    });

    test('when / map が値と失敗を正しく分岐する', () {
      const ok = Ok<int>(1);
      const err = Err<int>(NetworkFailure());
      expect(ok.when(ok: (v) => 'v$v', err: (f) => 'e'), 'v1');
      expect(err.when(ok: (v) => 'v$v', err: (f) => 'e'), 'e');
      expect(ok.map((v) => v + 1).valueOrNull, 2);
      expect(err.map((v) => v + 1).failureOrNull, isA<NetworkFailure>());
    });
  });

  group('センシティブ情報のログマスキング（§15.2）', () {
    test('座席・整理番号・予約番号・住所・画像・URLはマスクされる', () {
      final masked = AppLogger.maskContext({
        'seat': 'アリーナA1列10番',
        'entry_number': '123',
        'reservation_number': 'RSV-999',
        'address': '東京都新宿区1-2-3',
        'image_path': 'tickets/u1/t1.jpg',
        'ticket_url': 'https://example.com/t/1',
        'depart_at': '2026-07-10T08:00',
        'checkin_date': '2026-07-10',
        'password': 'hunter2',
        'genba_title': 'サマーライブ',
        'count': 3,
      });
      expect(masked['seat'], AppLogger.maskText);
      expect(masked['entry_number'], AppLogger.maskText);
      expect(masked['reservation_number'], AppLogger.maskText);
      expect(masked['address'], AppLogger.maskText);
      expect(masked['image_path'], AppLogger.maskText);
      expect(masked['ticket_url'], AppLogger.maskText);
      expect(masked['depart_at'], AppLogger.maskText);
      expect(masked['checkin_date'], AppLogger.maskText);
      expect(masked['password'], AppLogger.maskText);
      // 非センシティブ項目は残る
      expect(masked['genba_title'], 'サマーライブ');
      expect(masked['count'], 3);
    });

    test('camelCaseキー（Dartフィールド名由来）でもマスクされる（R8監査是正）', () {
      // context には JSON/DB由来の snake_case だけでなく、Dartの
      // フィールド名（camelCase）がそのまま渡される呼び出しもあり得る。
      // 旧実装は 'from_place' 等のパターンがアンダースコア込みだったため
      // 'fromPlace'（小文字化すると 'fromplace'）に一致せず素通りしていた。
      final masked = AppLogger.maskContext({
        'entryNumber': '123',
        'fromPlace': '東京駅',
        'toPlace': '大阪駅',
        'reservationNumber': 'RSV-999',
      });
      expect(masked['entryNumber'], AppLogger.maskText);
      expect(masked['fromPlace'], AppLogger.maskText);
      expect(masked['toPlace'], AppLogger.maskText);
      expect(masked['reservationNumber'], AppLogger.maskText);
    });

    test('ネストした Map / List 内もマスクされる', () {
      final masked = AppLogger.maskContext({
        'payload': {
          'seat': 'S席',
          'items': [
            {'reservation': 'R-1', 'name': 'ホテル'},
          ],
        },
      });
      final payload = masked['payload']! as Map<String, Object?>;
      expect(payload['seat'], AppLogger.maskText);
      final items = payload['items']! as List<Object?>;
      final first = items.first! as Map<String, Object?>;
      expect(first['reservation'], AppLogger.maskText);
      expect(first['name'], 'ホテル');
    });

    test('出力行にセンシティブ値が含まれない', () {
      final lines = <String>[];
      final logger = AppLogger(minLevel: LogLevel.debug, output: lines.add);
      logger.info(
        'ticket saved',
        context: {'seat': 'A-10', 'genba_id': 'g1'},
      );
      expect(lines, hasLength(1));
      expect(lines.first, isNot(contains('A-10')));
      expect(lines.first, contains('g1'));
    });

    test('minLevel未満のログは出力されない', () {
      final lines = <String>[];
      final logger = AppLogger(minLevel: LogLevel.warn, output: lines.add);
      logger.info('quiet');
      logger.error('loud');
      expect(lines, hasLength(1));
      expect(lines.first, contains('loud'));
    });
  });
}
