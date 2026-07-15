import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/features/social/data/friend_repository_impl.dart';

/// 未接続（デモ・未ログイン）では全操作が [UnavailableFailure] を返すこと。
/// フレンドコード申請も同様に扱う（追加要件）。
void main() {
  const repo = UnavailableFriendRepository();

  test('sendRequestByCode は未接続時に UnavailableFailure を返す', () async {
    final result = await repo.sendRequestByCode('OSHI-7K3P-Q9A2');
    expect(result.isOk, isFalse);
    expect(result.failureOrNull, isA<UnavailableFailure>());
  });

  test('sendRequest も未接続時は UnavailableFailure（回帰）', () async {
    final result = await repo.sendRequest('u2');
    expect(result.failureOrNull, isA<UnavailableFailure>());
  });
}
