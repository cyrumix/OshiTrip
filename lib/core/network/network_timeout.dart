import 'dart:async';

import 'package:http/http.dart' as http;

/// Supabase 等の外部通信に課す共通タイムアウト（R8-C / H-A）。
///
/// 無期限ハングを禁止する。1回の HTTP 往復がこの時間を超えたら中断し、
/// 呼び出し側で `NetworkFailure` へ変換して Outbox を pending へ戻す／UI の
/// スピナーを終了させる。既存の接続監視 probe（5秒, connectivityProvider）
/// とは別に、実データ操作（RPC / 認証 / Storage）向けに少し長めにとる。
const Duration kRemoteCallTimeout = Duration(seconds: 20);

/// 外部通信 Future に共通タイムアウトを課すヘルパ。
///
/// タイムアウト時は [TimeoutException] を投げる。呼び出し側は
/// `on TimeoutException` もしくは既存の catch で `NetworkFailure` へ変換する。
extension RemoteCallTimeout<T> on Future<T> {
  Future<T> withRemoteTimeout([Duration timeout = kRemoteCallTimeout]) =>
      this.timeout(timeout);
}

/// Supabase 全体（Auth / PostgREST / Storage / Realtime のHTTP層）へ、
/// リクエスト単位の共通タイムアウトを課す http クライアント（R8-C / H-A）。
///
/// `Supabase.initialize(httpClient: ...)` に渡す。個々の呼び出しに
/// [RemoteCallTimeout] を付け忘れても、トランスポート層で必ずタイムアウトが
/// 効く多層防御。タイムアウト時は基底クライアントの送信が [TimeoutException]
/// を投げ、上位（postgrest/gotrue/storage）を通じて呼び出し側の catch で
/// `NetworkFailure` 等へ変換される。
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient(this._inner, {this.timeout = kRemoteCallTimeout});

  final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(timeout);

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
