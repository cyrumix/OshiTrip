import 'package:flutter/foundation.dart';

import '../../../core/error/result.dart';
import '../domain/routes_gateway.dart';

/// 「最新ルートを更新」の実行を扱う（旅程Phase 4, itinerary-plan-spec §6.3/§8.3）。
///
/// - **single-flight**: 同一 fingerprint の同時呼び出しは同じ Future を共有する
///   （二重タップ・複数箇所からの同時起動でも Google 呼び出しは1回になる）。
/// - 呼び出しは [recalculate] を明示的に呼んだときだけ発生する。初期表示・
///   並び替え・保存ではこのクラスの誰も何も呼ばないため、費用は構造的に
///   増えない（呼び出し元が「経路を確認」「最新の経路」からのみ [recalculate]
///   を呼ぶ設計にする, §8.3）。
/// - **現仕様では経路取得を全ユーザーに開放する**（アプリ内にプレミアム/ノーマルの
///   正式なアカウント区分・課金導線が無いため）。クライアント側でプレミアム判定に
///   よる早期拒否は行わない。[isPremium] は将来のプレミアム化に備えて受け取るだけで
///   現時点では取得可否に使わない。実際の可否制御は Edge Function 側の
///   `ROUTES_REQUIRE_PREMIUM`（既定 false）・レート制限・kill switch が担う（D-232）。
class RouteRecalculationController {
  RouteRecalculationController({required RoutesGateway gateway})
      : _gateway = gateway;

  final RoutesGateway _gateway;

  final Map<String, Future<Result<RouteLiveResult>>> _inFlight = {};

  /// 現在進行中の fingerprint 一覧（テスト用: single-flight の可視化）。
  @visibleForTesting
  Set<String> get inFlightFingerprints => _inFlight.keys.toSet();

  Future<Result<RouteLiveResult>> recalculate({
    required RouteLiveRequest request,
    // 将来のプレミアム化に備えて受け取るが、現仕様では取得可否に使わない（D-232）。
    required bool isPremium,
    required String fingerprint,
  }) {
    final existing = _inFlight[fingerprint];
    if (existing != null) return existing;
    final future = _gateway.computeRoute(request).whenComplete(() {
      _inFlight.remove(fingerprint);
    });
    _inFlight[fingerprint] = future;
    return future;
  }
}
