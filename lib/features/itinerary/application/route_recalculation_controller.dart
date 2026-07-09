import 'package:flutter/foundation.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../domain/routes_gateway.dart';

/// 「最新ルートを更新」の実行を扱う（旅程Phase 4, itinerary-plan-spec §6.3/§8.3）。
///
/// - **single-flight**: 同一 fingerprint の同時呼び出しは同じ Future を共有する
///   （二重タップ・複数箇所からの同時起動でも Google 呼び出しは1回になる）。
/// - 呼び出しは [recalculate] を明示的に呼んだときだけ発生する。初期表示・
///   並び替え・保存ではこのクラスの誰も何も呼ばないため、費用は構造的に
///   増えない（呼び出し元が「経路詳細を開く」「最新ルートを更新」からのみ
///   [recalculate] を呼ぶ設計にする, §8.3）。
/// - 非プレミアムは Gateway を呼ばずに型付き拒否を返す（クライアント側の早期
///   ガード。実強制は Edge Function 側の entitlement 検証であり、ここは
///   UXヒントに過ぎない——クライアントの [isPremium] を偽装してもサーバーが
///   拒否する）。
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
    required bool isPremium,
    required String fingerprint,
  }) {
    if (!isPremium) {
      return Future.value(
        const Err(PermissionFailure(message: '最新ルートの取得はプレミアム限定の機能です')),
      );
    }
    final existing = _inFlight[fingerprint];
    if (existing != null) return existing;
    final future = _gateway.computeRoute(request).whenComplete(() {
      _inFlight.remove(fingerprint);
    });
    _inFlight[fingerprint] = future;
    return future;
  }
}
