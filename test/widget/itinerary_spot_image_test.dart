import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/images/image_store.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/features/itinerary/presentation/itinerary_spot_image.dart';
import 'package:path/path.dart' as p;

/// Phase 2レビュー点6: スポットのユーザー画像を型付き状態（present / missing /
/// inaccessible）で表示し、代替テキスト（Semantics alt）に施設名を含める。
void main() {
  const ownerId = 'demo-user-1';

  // 1x1 透明PNG。
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgYGAAAAAEAAH2FzhVAAAAAElFTkSuQmCC',
  );

  Future<({ImageStore store, Directory dir})> makeStore() async {
    final dir = Directory.systemTemp.createTempSync('oshi_itin_img');
    addTearDown(() => dir.deleteSync(recursive: true));
    return (store: ImageStore(dir), dir: dir);
  }

  Widget host(ImageStore store, String? ref) => ProviderScope(
        overrides: [imageStoreProvider.overrideWithValue(store)],
        child: MaterialApp(
          home: Scaffold(
            body: ItinerarySpotImage(
              ownerId: ownerId,
              imageRef: ref,
              facilityName: '海遊館',
            ),
          ),
        ),
      );

  testWidgets('present: 画像を表示し alt に施設名を含む', (tester) async {
    final img = await makeStore();
    const ref = 'images/$ownerId/itinerary_spot/pic.png';
    final file = File(p.joinAll([img.dir.path, ...ref.split('/')]))
      ..createSync(recursive: true)
      ..writeAsBytesSync(pngBytes);
    expect(file.existsSync(), isTrue);

    await tester.pumpWidget(host(img.store, ref));
    await tester.pump();

    expect(find.bySemanticsLabel('海遊館 の画像'), findsOneWidget);
    // 見つからない/読み込めない表示は出ない。
    expect(find.text('画像が見つかりません'), findsNothing);
  });

  testWidgets('missing: 見つからない旨と施設名入り alt を出す', (tester) async {
    final img = await makeStore();
    const ref = 'images/$ownerId/itinerary_spot/gone.png';

    await tester.pumpWidget(host(img.store, ref));
    await tester.pump();

    expect(find.text('画像が見つかりません'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('海遊館 の画像は見つかりません')),
      findsWidgets,
    );
  });

  testWidgets('inaccessible: 読み込めない旨と再試行導線を出す', (tester) async {
    final img = await makeStore();
    const ref = 'images/$ownerId/itinerary_spot/locked.png';
    // ファイル位置にディレクトリを置く = 読めない状態（H-04 item3 の実分岐）。
    Directory(p.joinAll([img.dir.path, ...ref.split('/')]))
        .createSync(recursive: true);

    await tester.pumpWidget(host(img.store, ref));
    await tester.pump();

    expect(find.text('読み込めません'), findsOneWidget);
    expect(find.text('再試行'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('海遊館 の画像を読み込めません')),
      findsWidgets,
    );
  });

  testWidgets('未設定（ref=null）は何も表示しない', (tester) async {
    final img = await makeStore();
    await tester.pumpWidget(host(img.store, null));
    await tester.pump();
    expect(find.byType(Image), findsNothing);
    expect(find.text('画像が見つかりません'), findsNothing);
  });
}
