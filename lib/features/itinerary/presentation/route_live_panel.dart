import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../application/itinerary_actions_controller.dart';
import '../application/routes_providers.dart';
import '../domain/itinerary_leg.dart';
import '../domain/itinerary_map_links.dart';
import '../domain/itinerary_value_origin.dart';
import '../domain/representative_time_bucket.dart';
import '../domain/route_request_fingerprint.dart';
import '../domain/routes_gateway.dart';
import 'external_link.dart';
import 'itinerary_import_and_leg.dart' show ItineraryEntryOption;

/// 移動区間カードの経路パネル（itinerary-plan-spec §6.3/§8.3）。
///
/// 役割を分けた3つの導線を提供する:
/// - **経路を確認**: アプリ内で Google Routes から経路を取得・表示する（計画時刻＝
///   区間の出発予定時刻ベース）。徒歩合計・公共交通の路線/乗換/発着時刻を表示。
/// - **最新の経路**: 押した時点の現在時刻を出発時刻として再取得する（当日・移動
///   直前用）。
/// - **Google Mapsで開く**: 外部の地図アプリ/ブラウザを開く補助導線。
///
/// Google のライブ結果は原則として画面状態の一時データ（D-180/D-181/D-215:
/// Routes コンテンツを恒久キャッシュへ昇格させない）。「この経路を保存」では、
/// ユーザーが確認のうえ **所要・距離だけ**を自分の概算（`userProvided`）として
/// 保存する（乗換ステップ等の Google コンテンツは保存しない, ToS準拠）。
class RouteLivePanel extends ConsumerStatefulWidget {
  const RouteLivePanel({
    super.key,
    required this.origin,
    required this.destination,
    required this.travelMode,
    required this.existingLeg,
    this.planId,
  });

  final ItineraryEntryOption? origin;
  final ItineraryEntryOption? destination;
  final ItineraryTravelMode travelMode;
  final ItineraryLeg? existingLeg;

  /// 非nullなら「この経路を保存」を出せる（計画のleg更新に使う）。編集シート等で
  /// 保存導線が不要なときは null。
  final String? planId;

  @override
  ConsumerState<RouteLivePanel> createState() => _RouteLivePanelState();
}

class _RouteLivePanelState extends ConsumerState<RouteLivePanel> {
  Future<Result<RouteLiveResult>>? _liveFuture;
  bool _fetchedWithNow = false;
  String? _rangeNotice;
  bool _saving = false;

  /// Google Routes を呼べる端点か（Place ID または座標が必要）。
  RouteEndpoint? _routeEndpointOf(ItineraryEntryOption? o) {
    if (o == null || o.spotId == null) return null;
    final endpoint = RouteEndpoint(
      placeId: o.googlePlaceId,
      latitude: o.latitude,
      longitude: o.longitude,
    );
    return endpoint.hasLocation ? endpoint : null;
  }

  MapRouteEndpoint? _mapEndpointOf(ItineraryEntryOption? o) {
    if (o == null) return null;
    return MapRouteEndpoint(
      name: o.label,
      address: o.address,
      latitude: o.latitude,
      longitude: o.longitude,
      placeId: o.googlePlaceId,
    );
  }

  static String? _googleTravelMode(ItineraryTravelMode m) => switch (m) {
        ItineraryTravelMode.walking => 'walking',
        ItineraryTravelMode.transit => 'transit',
        ItineraryTravelMode.driving || ItineraryTravelMode.taxi => 'driving',
        ItineraryTravelMode.bicycling => 'bicycling',
        ItineraryTravelMode.flight || ItineraryTravelMode.other => null,
      };

  @override
  void didUpdateWidget(covariant RouteLivePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.origin?.id != widget.origin?.id ||
        oldWidget.destination?.id != widget.destination?.id ||
        oldWidget.travelMode != widget.travelMode) {
      _liveFuture = null;
      _rangeNotice = null;
    }
  }

  void _fetch(
    RouteEndpoint origin,
    RouteEndpoint destination,
    bool isPremium, {
    required bool useNow,
  }) {
    final now = ref.read(clockProvider).now().toUtc();
    // 「経路を確認」は区間の出発予定時刻ベース、「最新の経路」は現在時刻ベース。
    final effectiveDeparture =
        useNow ? now : (widget.existingLeg?.departureAt ?? now);
    final bucket = resolveRepresentativeRequestTime(effectiveDeparture, now);
    if (widget.travelMode == ItineraryTravelMode.transit &&
        bucket.isOutOfSupportedRange) {
      setState(() {
        _rangeNotice = '公共交通の経路は、出発日時が現在から過去7日〜未来100日の'
            '範囲内のときだけ取得できます。日程を近づけるか、保存済みの概算経路・'
            '手動入力・Google Mapsをご利用ください。';
        _liveFuture = null;
      });
      return;
    }
    final fingerprint = routeRequestFingerprint(
      originSignature: origin.signature,
      destinationSignature: destination.signature,
      travelMode: widget.travelMode,
      representativeTimeBucket: bucket.bucketLabel,
    );
    final request = RouteLiveRequest(
      origin: origin,
      destination: destination,
      travelMode: widget.travelMode,
      representativeDepartureUtc: bucket.requestUtc,
    );
    setState(() {
      _rangeNotice = null;
      _fetchedWithNow = useNow;
      _liveFuture = ref.read(routeRecalculationControllerProvider).recalculate(
            request: request,
            isPremium: isPremium,
            fingerprint: fingerprint,
          );
    });
  }

  /// ユーザーが確認して「所要・距離だけ」を自分の概算として保存する（明示変換,
  /// D-180/D-181・ToS準拠。乗換ステップ等の Google コンテンツは保存しない）。
  Future<void> _saveEstimate(RouteLiveResult result) async {
    final leg = widget.existingLeg;
    final planId = widget.planId;
    if (leg == null || planId == null || _saving) return;
    final o = _mapEndpointOf(widget.origin);
    final d = _mapEndpointOf(widget.destination);
    final mapsUrl = (o != null && d != null)
        ? googleMapsRouteUrl(
            origin: o,
            destination: d,
            travelMode: _googleTravelMode(widget.travelMode),
          )?.toString()
        : null;
    setState(() => _saving = true);
    final now = ref.read(clockProvider).now().toUtc();
    final updated = leg.copyWith(
      durationMinutes: result.durationMinutes,
      distanceMeters: result.distanceMeters,
      googleMapsUrl: mapsUrl ?? leg.googleMapsUrl,
      lastVerifiedAt: now,
      updatedAt: now,
    );
    final failure = await ref
        .read(itineraryActionsControllerProvider(planId).notifier)
        .upsertLeg(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure == null ? '所要・距離を保存しました' : failure.message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leg = widget.existingLeg;
    final mapOrigin = _mapEndpointOf(widget.origin);
    final mapDest = _mapEndpointOf(widget.destination);
    final mapsUrl = (mapOrigin != null && mapDest != null)
        ? googleMapsRouteUrl(
            origin: mapOrigin,
            destination: mapDest,
            travelMode: _googleTravelMode(widget.travelMode),
          )
        : null;
    final routeOrigin = _routeEndpointOf(widget.origin);
    final routeDest = _routeEndpointOf(widget.destination);
    final canFetch = routeOrigin != null &&
        routeDest != null &&
        _googleTravelMode(widget.travelMode) != null;
    final isPremium = ref.watch(routesIsPremiumProvider).valueOrNull ?? false;

    // 端点情報が全く無い（名前も座標もPlace IDも無い）ときは何も出さない。
    if (mapsUrl == null && !canFetch) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16),
        if (leg != null) _SavedEstimateView(leg: leg),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (canFetch)
              TextButton.icon(
                key: const Key('route_check_button'),
                onPressed: () => _fetch(
                  routeOrigin,
                  routeDest,
                  isPremium,
                  useNow: false,
                ),
                icon: const Icon(Icons.directions_outlined, size: 18),
                label: const Text('経路を確認'),
              ),
            if (canFetch)
              TextButton.icon(
                key: const Key('route_latest_button'),
                onPressed: () => _fetch(
                  routeOrigin,
                  routeDest,
                  isPremium,
                  useNow: true,
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('最新の経路'),
              ),
            if (mapsUrl != null)
              TextButton.icon(
                key: const Key('route_maps_button'),
                onPressed: () => openExternalUrlWithConfirm(
                  context,
                  url: mapsUrl.toString(),
                  label: 'Google Mapsで経路を開く',
                ),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Google Mapsで開く'),
              ),
          ],
        ),
        if (_rangeNotice != null)
          Padding(
            key: const Key('route_range_notice'),
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _rangeNotice!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
        if (_liveFuture != null)
          FutureBuilder<Result<RouteLiveResult>>(
            future: _liveFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      key: Key('route_live_loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              final result = snapshot.data;
              if (result == null) return const SizedBox.shrink();
              return result.when(
                ok: (live) {
                  return _LiveResultView(
                    result: live,
                    fetchedWithNow: _fetchedWithNow,
                    canSave:
                        widget.planId != null && widget.existingLeg != null,
                    saving: _saving,
                    onSave: () => _saveEstimate(live),
                  );
                },
                err: (failure) => Padding(
                  key: const Key('route_live_error'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    failure.message,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _SavedEstimateView extends StatelessWidget {
  const _SavedEstimateView({required this.leg});
  final ItineraryLeg leg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (leg.durationMinutes != null) '${leg.durationMinutes}分',
      if (leg.distanceMeters != null)
        '${(leg.distanceMeters! / 1000).toStringAsFixed(1)}km',
      if (leg.fareAmountMinor != null) formatJpyYen(leg.fareAmountMinor!),
    ];
    if (parts.isEmpty) {
      return Text('保存済みの概算経路はまだありません。', style: theme.textTheme.bodySmall);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '保存済み概算: ${parts.join(' / ')}',
          key: const Key('route_saved_estimate'),
          style: theme.textTheme.bodyMedium,
        ),
        Text(
          '出典: ${leg.valueOrigin.label}'
          '${leg.lastVerifiedAt != null ? ' ・確認 ${_formatDate(leg.lastVerifiedAt!)}' : ''}',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}/${l.month}/${l.day}';
  }
}

/// アプリ内で取得した経路の結果表示（所要・距離・徒歩合計・公共交通の乗換
/// タイムライン。発着時刻付き）。運賃は通常UIに出さない（item 4）。
class _LiveResultView extends StatelessWidget {
  const _LiveResultView({
    required this.result,
    required this.fetchedWithNow,
    required this.canSave,
    required this.saving,
    required this.onSave,
  });

  final RouteLiveResult result;
  final bool fetchedWithNow;
  final bool canSave;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('route_live_result'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${fetchedWithNow ? '最新経路' : '経路'}: '
            '合計${result.durationMinutes}分 / '
            '${(result.distanceMeters / 1000).toStringAsFixed(1)}km'
            '${result.walkMinutes > 0 ? ' ・徒歩 合計${result.walkMinutes}分' : ''}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          for (final step in result.transitSteps)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.directions_transit,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _stepLabel(step),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '取得: ${_formatDateTime(result.requestedAt)}'
            '（概算。最新ではない可能性があります）',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          Row(
            children: [
              Icon(
                Icons.map_outlined,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text('Google Maps', style: theme.textTheme.labelSmall),
              const Spacer(),
              if (canSave)
                TextButton(
                  key: const Key('route_save_button'),
                  onPressed: saving ? null : onSave,
                  child: Text(saving ? '保存中…' : 'この経路を保存'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 「10:30 発 東京 → 10:45 着 新宿（山手線・新宿方面）」のような1行。
  static String _stepLabel(RouteLiveTransitStep step) {
    final line = step.lineNameShort ?? step.lineName;
    final head = step.headsign != null ? '・${step.headsign}方面' : '';
    final dep = step.departureTime;
    final arr = step.arrivalTime;
    final from = step.departureStopName;
    final to = step.arrivalStopName;
    final timePart = (dep != null || arr != null)
        ? '${dep ?? '—'} 発 → ${arr ?? '—'} 着 '
        : '';
    final stopPart = (from != null && to != null) ? '$from → $to ' : '';
    return '$timePart$stopPart（$line$head）';
  }

  String _formatDateTime(DateTime d) {
    final l = d.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${l.month}/${l.day} $hh:$mm';
  }
}
