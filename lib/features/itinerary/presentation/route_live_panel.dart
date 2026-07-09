import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../application/routes_providers.dart';
import '../domain/itinerary_leg.dart';
import '../domain/itinerary_value_origin.dart';
import '../domain/representative_time_bucket.dart';
import '../domain/route_request_fingerprint.dart';
import '../domain/routes_gateway.dart';
import 'external_link.dart';
import 'itinerary_import_and_leg.dart' show ItineraryEntryOption;

/// 移動区間の経路詳細パネル（旅程Phase 4, itinerary-plan-spec §6.3/§8.3）。
///
/// 登録スポット↔スポットの区間だけを対象にする（端点のどちらかが
/// transport/lodging/note、または座標・Place IDが無いスポットなら何も
/// 表示しない）。保存済み概算は常時閲覧可（非プレミアム含む）。Google Routes
/// への問い合わせは「経路詳細を開く」「最新ルートを更新」の**明示タップ**
/// からのみ発生し、この Widget を build するだけでは一切呼ばれない。
///
/// Google のライブ結果は画面状態にのみ保持し、手動入力欄への自動コピーは
/// 行わない（D-215: Places同様、ユーザーが確認のうえ目視で入力し直す）。
class RouteLivePanel extends ConsumerStatefulWidget {
  const RouteLivePanel({
    super.key,
    required this.origin,
    required this.destination,
    required this.travelMode,
    required this.existingLeg,
  });

  final ItineraryEntryOption? origin;
  final ItineraryEntryOption? destination;
  final ItineraryTravelMode travelMode;
  final ItineraryLeg? existingLeg;

  @override
  ConsumerState<RouteLivePanel> createState() => _RouteLivePanelState();
}

class _RouteLivePanelState extends ConsumerState<RouteLivePanel> {
  bool _expanded = false;
  Future<Result<RouteLiveResult>>? _liveFuture;

  /// 公共交通の代表時刻が Google Routes の対応範囲外（過去7日〜未来100日）の
  /// ときの案内文言。設定されている間は Google Routes を呼ばない（修正5）。
  String? _rangeNotice;

  RouteEndpoint? _endpointOf(ItineraryEntryOption? o) {
    if (o == null || o.spotId == null) return null;
    final endpoint = RouteEndpoint(
      placeId: o.googlePlaceId,
      latitude: o.latitude,
      longitude: o.longitude,
    );
    return endpoint.hasLocation ? endpoint : null;
  }

  @override
  void didUpdateWidget(covariant RouteLivePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 端点・手段が変わったら、古い組み合わせの展開状態・取得結果を
    // 新しい組み合わせへ持ち越さない。
    if (oldWidget.origin?.id != widget.origin?.id ||
        oldWidget.destination?.id != widget.destination?.id ||
        oldWidget.travelMode != widget.travelMode) {
      _expanded = false;
      _liveFuture = null;
      _rangeNotice = null;
    }
  }

  RepresentativeRequestTime _representativeTime() {
    final now = ref.read(clockProvider).now().toUtc();
    final effectiveDeparture = widget.existingLeg?.departureAt ?? now;
    return resolveRepresentativeRequestTime(effectiveDeparture, now);
  }

  void _fetch(RouteEndpoint origin, RouteEndpoint destination, bool isPremium) {
    final bucket = _representativeTime();
    // 公共交通は対応範囲（過去7日〜未来100日）外だと Google Routes が取得
    // できないため、**呼ぶ前に**案内を出して API を呼ばない（修正5）。保存済み
    // 概算・手動入力はそのまま使える。
    if (widget.travelMode == ItineraryTravelMode.transit &&
        bucket.isOutOfSupportedRange) {
      setState(() {
        _rangeNotice = '公共交通の最新経路は、出発日時が現在から過去7日〜未来100日の'
            '範囲内のときだけ取得できます。日程を近づけるか、保存済みの概算経路・'
            '手動入力をご利用ください。';
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
      _liveFuture = ref.read(routeRecalculationControllerProvider).recalculate(
            request: request,
            isPremium: isPremium,
            fingerprint: fingerprint,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final origin = _endpointOf(widget.origin);
    final destination = _endpointOf(widget.destination);
    if (origin == null || destination == null) {
      return const SizedBox.shrink(); // スポット↔スポットのみ対象（§6冒頭）
    }
    final theme = Theme.of(context);
    final isPremium = ref.watch(routesIsPremiumProvider).valueOrNull ?? false;
    final leg = widget.existingLeg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        InkWell(
          key: const Key('route_detail_toggle'),
          onTap: () {
            final wasExpanded = _expanded;
            setState(() => _expanded = !_expanded);
            // 非プレミアムは保存済み概算＋案内表示のみで、取得試行自体を行わない
            // （呼んでも拒否されるだけの空振りを避ける）。
            if (!wasExpanded && _liveFuture == null && isPremium) {
              _fetch(origin, destination, isPremium);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 8),
                Text('経路詳細', style: theme.textTheme.titleSmall),
              ],
            ),
          ),
        ),
        if (leg != null) _SavedEstimateView(leg: leg),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (_rangeNotice != null)
            Padding(
              key: const Key('route_range_notice'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _rangeNotice!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          if (!isPremium)
            Text(
              '最新ルートの取得はプレミアム限定です。保存済みの概算経路は引き続き閲覧できます。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('route_refresh_button'),
                onPressed: () => _fetch(origin, destination, isPremium),
                icon: const Icon(Icons.refresh),
                label: const Text('最新ルートを更新'),
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
                  ok: (live) => _LiveResultView(
                    result: live,
                    origin: origin,
                    destination: destination,
                  ),
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
      if (leg.fareAmountMinor != null && leg.fareCurrency != null)
        '${leg.fareCurrency} ${leg.fareAmountMinor}',
    ];
    if (parts.isEmpty) {
      return Text('保存済みの概算経路はまだありません。', style: theme.textTheme.bodySmall);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
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
      ),
    );
  }

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.year}/${l.month}/${l.day}';
  }
}

class _LiveResultView extends StatelessWidget {
  const _LiveResultView({
    required this.result,
    required this.origin,
    required this.destination,
  });

  final RouteLiveResult result;
  final RouteEndpoint origin;
  final RouteEndpoint destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapsUrl = googleMapsDirectionsUrl(origin, destination);
    return Container(
      key: const Key('route_live_result'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '最新: ${result.durationMinutes}分 / '
            '${(result.distanceMeters / 1000).toStringAsFixed(1)}km'
            '${result.fareText != null ? ' / ${result.fareText}' : ''}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          for (final step in result.transitSteps)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${step.lineNameShort ?? step.lineName}'
                '${step.headsign != null ? '（${step.headsign}方面）' : ''}'
                '${step.departureStopName != null && step.arrivalStopName != null ? '：${step.departureStopName} → ${step.arrivalStopName}' : ''}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '取得: ${_formatDateTime(result.requestedAt)}（概算・最新ではない可能性があります）',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 4),
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
              if (mapsUrl != null)
                TextButton(
                  onPressed: () => openExternalUrlWithConfirm(
                    context,
                    url: mapsUrl.toString(),
                    label: 'Google Mapsで経路を開く',
                  ),
                  child: const Text('Google Mapsで開く'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    final l = d.toLocal();
    final hh = l.hour.toString().padLeft(2, '0');
    final mm = l.minute.toString().padLeft(2, '0');
    return '${l.month}/${l.day} $hh:$mm';
  }
}
