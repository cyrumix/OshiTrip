import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/itinerary/application/itinerary_timeline.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot.dart';

import '../helpers/fixtures.dart';

/// 移動区間の出発/到着など、タイムライン項目の表示名（修正1/修正5）。
///
/// 内部の種別コード（`spot`/`transport`/`lodging`/`note`）や ID をユーザーに
/// 見せず、施設名・予定名・交通名などの日本語表示名を使うことを保証する。
ItineraryTimelineEntry _entry({
  required ItineraryEntryKind kind,
  ItinerarySpot? spot,
  Transport? transport,
  Lodging? lodging,
  String? titleOverride,
  ItineraryReferenceStatus status = ItineraryReferenceStatus.resolved,
}) =>
    ItineraryTimelineEntry(
      entry: makeItineraryEntry(kind: kind, titleOverride: titleOverride),
      spot: spot,
      transport: transport,
      lodging: lodging,
      referenceStatus: status,
    );

void main() {
  test('内部の種別コード（spot/transport/lodging/note）を表示名に出さない', () {
    final labels = [
      itineraryTimelineEntryLabel(
        _entry(
          kind: ItineraryEntryKind.spot,
          spot: makeItinerarySpot(name: '東京タワー'),
        ),
      ),
      itineraryTimelineEntryLabel(
        _entry(
          kind: ItineraryEntryKind.transport,
          transport: makeTransportRef(method: TransportMethod.shinkansen),
        ),
      ),
      itineraryTimelineEntryLabel(
        _entry(
          kind: ItineraryEntryKind.lodging,
          lodging: makeLodgingRef(name: 'ホテル日和'),
        ),
      ),
      itineraryTimelineEntryLabel(
        _entry(kind: ItineraryEntryKind.note, titleOverride: '集合'),
      ),
    ];
    for (final l in labels) {
      expect(l, isNot(contains('transport')));
      expect(l, isNot(contains('lodging')));
      expect(l, isNot(contains('spot')));
      expect(l, isNot(equals('note')));
    }
  });

  test('スポットは施設名を表示する', () {
    final label = itineraryTimelineEntryLabel(
      _entry(
        kind: ItineraryEntryKind.spot,
        spot: makeItinerarySpot(name: '清水寺'),
      ),
    );
    expect(label, '清水寺');
  });

  test('交通は方向＋手段（例: 往路 新幹線）を表示する', () {
    final outbound = itineraryTimelineEntryLabel(
      _entry(
        kind: ItineraryEntryKind.transport,
        transport: makeTransportRef(
          direction: TransportDirection.outbound,
          method: TransportMethod.shinkansen,
        ),
      ),
    );
    expect(outbound, '往路 新幹線');

    final inbound = itineraryTimelineEntryLabel(
      _entry(
        kind: ItineraryEntryKind.transport,
        transport: makeTransportRef(
          direction: TransportDirection.inbound,
          method: TransportMethod.airplane,
        ),
      ),
    );
    expect(inbound, '復路 飛行機');
  });

  test('宿泊は宿泊施設名を表示し、未設定なら「宿泊先」', () {
    expect(
      itineraryTimelineEntryLabel(
        _entry(
          kind: ItineraryEntryKind.lodging,
          lodging: makeLodgingRef(name: 'グランドホテル'),
        ),
      ),
      'グランドホテル',
    );
    expect(
      itineraryTimelineEntryLabel(
        _entry(
          kind: ItineraryEntryKind.lodging,
          lodging: makeLodgingRef(),
        ),
      ),
      '宿泊先',
    );
  });

  test('メモはタイトルがあればそれを、なければ「メモ」', () {
    expect(
      itineraryTimelineEntryLabel(
        _entry(kind: ItineraryEntryKind.note, titleOverride: '待ち合わせ'),
      ),
      '待ち合わせ',
    );
    expect(
      itineraryTimelineEntryLabel(
        _entry(kind: ItineraryEntryKind.note),
      ),
      'メモ',
    );
  });

  test('参照切れ（削除済み）はユーザーに分かる日本語で示す', () {
    expect(
      itineraryTimelineEntryLabel(
        _entry(
          kind: ItineraryEntryKind.transport,
          status: ItineraryReferenceStatus.missing,
        ),
      ),
      '削除済みの交通',
    );
    expect(
      itineraryTimelineEntryLabel(
        _entry(
          kind: ItineraryEntryKind.lodging,
          status: ItineraryReferenceStatus.missing,
        ),
      ),
      '削除済みの宿泊',
    );
    expect(
      itineraryTimelineEntryLabel(
        _entry(
          kind: ItineraryEntryKind.spot,
          status: ItineraryReferenceStatus.missing,
        ),
      ),
      '削除済みのスポット',
    );
  });
}
