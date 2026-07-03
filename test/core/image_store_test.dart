import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshi_trip/core/images/image_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory baseDir;
  late Directory srcDir;
  late ImageStore store;

  setUp(() {
    baseDir = Directory.systemTemp.createTempSync('oshi_img_base');
    srcDir = Directory.systemTemp.createTempSync('oshi_img_src');
    store = ImageStore(baseDir);
  });

  tearDown(() {
    if (baseDir.existsSync()) baseDir.deleteSync(recursive: true);
    if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
  });

  File makeSource(String name, String content) {
    final f = File(p.join(srcDir.path, name));
    f.writeAsStringSync(content);
    return f;
  }

  test('import はアプリ管理領域へコピーし、一時ファイル削除後も読める', () async {
    final src = makeSource('pick.jpg', 'PHOTO-BYTES');
    final ref = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.memoryPhoto,
      source: src,
    );

    // ImagePicker の一時ファイルを削除しても…
    src.deleteSync();
    // …コピー済み画像は owner スコープで解決・表示できる。
    final resolved = store.resolveOwned('user-A', ref);
    expect(resolved.existsSync(), isTrue);
    expect(resolved.readAsStringSync(), 'PHOTO-BYTES');
    expect(await store.statusOf('user-A', ref), ImageAssetStatus.present);
  });

  test('参照は owner/用途別ディレクトリの推測困難名、拡張子は保持', () async {
    final src = makeSource('pick.png', 'x');
    final ref = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.memoryPhoto,
      source: src,
    );
    final parts = ref.split('/');
    expect(parts[0], 'images');
    expect(parts[1], 'user-A');
    expect(parts[2], 'memory'); // memoryPhoto の dir
    expect(parts[3], endsWith('.png'));
    expect(parts[3].length, greaterThan(20)); // uuid ベースで推測困難
    // 元のファイル名は使わない。
    expect(ref, isNot(contains('pick')));
  });

  test('チケット画像は専用ディレクトリで、backupExcluder が実絶対パスで呼ばれる', () async {
    final excluded = <String>[];
    final s = ImageStore(
      baseDir,
      backupExcluder: (path) async {
        excluded.add(path);
      },
    );
    final ref = await s.import(
      ownerId: 'user-A',
      category: ImageCategory.ticket,
      source: makeSource('t.jpg', 'T'),
    );
    expect(ref.split('/')[2], 'ticket');
    expect(ImageCategory.ticket.isSensitive, isTrue);
    expect(ImageCategory.memoryPhoto.isSensitive, isFalse);
    // 機密画像はバックアップ除外が実行される（no-op ではない）。
    expect(excluded, hasLength(1));
    expect(excluded.single, s.resolveOwned('user-A', ref).path);
    expect(p.isAbsolute(excluded.single), isTrue);
  });

  test('非機密画像では backupExcluder を呼ばない', () async {
    final excluded = <String>[];
    final s = ImageStore(
      baseDir,
      backupExcluder: (path) async {
        excluded.add(path);
      },
    );
    await s.import(
      ownerId: 'user-A',
      category: ImageCategory.memoryPhoto,
      source: makeSource('m.jpg', 'M'),
    );
    expect(excluded, isEmpty);
  });

  test('バックアップ除外に失敗したら import は失敗し、生成ファイルを残さない', () async {
    final s = ImageStore(
      baseDir,
      backupExcluder: (_) async => throw const FileSystemException('excl'),
    );
    await expectLater(
      s.import(
        ownerId: 'user-A',
        category: ImageCategory.ticket,
        source: makeSource('t.jpg', 'SECRET'),
      ),
      throwsA(isA<ImageStorageException>()),
    );
    // 除外できなかった機密画像は確定保存されない（孤立ファイルも残さない）。
    final ticketDir = Directory(
      p.join(baseDir.path, 'images', 'user-A', 'ticket'),
    );
    final leftovers = ticketDir.existsSync()
        ? ticketDir.listSync()
        : const <FileSystemEntity>[];
    expect(leftovers, isEmpty);
  });

  test('コピー元が存在しない場合は ImageStorageException（中間ファイルを残さない）', () async {
    final missing = File(p.join(srcDir.path, 'nope.jpg'));
    await expectLater(
      store.import(
        ownerId: 'user-A',
        category: ImageCategory.memoryPhoto,
        source: missing,
      ),
      throwsA(isA<ImageStorageException>()),
    );
    final dir = Directory(p.join(baseDir.path, 'images', 'user-A', 'memory'));
    final leftovers =
        dir.existsSync() ? dir.listSync() : const <FileSystemEntity>[];
    expect(leftovers, isEmpty);
  });

  test('読み取り不能（ファイル位置がディレクトリ）は inaccessible に変換する', () async {
    // 参照先パスにディレクトリを作り、ファイルとして読めない状態を作る。
    const ref = 'images/user-A/memory/locked.jpg';
    Directory(p.joinAll([baseDir.path, ...ref.split('/')]))
        .createSync(recursive: true);
    expect(await store.statusOf('user-A', ref), ImageAssetStatus.inaccessible);
  });

  test('hero/oshi 画像も owner スコープで別ユーザーからの解決を拒否する', () async {
    final heroRef = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.genbaHero,
      source: makeSource('h.jpg', 'HERO-A'),
    );
    final oshiRef = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.oshiImage,
      source: makeSource('o.jpg', 'OSHI-A'),
    );
    expect(heroRef.split('/')[2], 'hero');
    expect(oshiRef.split('/')[2], 'oshi');

    // 別 owner(user-B) は解決できない（例外/ null/ missing）。
    expect(
      () => store.resolveOwned('user-B', heroRef),
      throwsA(isA<ImageAccessException>()),
    );
    expect(store.tryResolveOwned('user-B', oshiRef), isNull);
    expect(await store.statusOf('user-B', heroRef), ImageAssetStatus.missing);

    // 本人は解決できる（対照）。
    expect(store.resolveOwned('user-A', heroRef).existsSync(), isTrue);
    expect(store.tryResolveOwned('user-A', oshiRef)!.existsSync(), isTrue);
  });

  test('編集キャンセル相当: セッション import を消しても保存済み画像は残る', () async {
    // 保存済み（既存）画像。
    final saved = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.ticket,
      source: makeSource('saved.jpg', 'SAVED'),
    );
    // 編集セッションで import した未確定画像（差替え候補）。
    final sessionRef = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.ticket,
      source: makeSource('draft.jpg', 'DRAFT'),
    );

    // キャンセル: セッション import だけを owner スコープで削除する。
    await store.deleteRef('user-A', sessionRef);

    expect(
      await store.statusOf('user-A', sessionRef),
      ImageAssetStatus.missing,
    );
    expect(await store.statusOf('user-A', saved), ImageAssetStatus.present);
  });

  test('欠損は missing 状態に変換する', () async {
    expect(
      await store.statusOf('user-A', 'images/user-A/memory/nonexistent.jpg'),
      ImageAssetStatus.missing,
    );
  });

  test('deleteRef は自分の owner の参照だけ削除する', () async {
    final aRef = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.memoryPhoto,
      source: makeSource('a.jpg', 'A'),
    );
    final bRef = await store.import(
      ownerId: 'user-B',
      category: ImageCategory.memoryPhoto,
      source: makeSource('b.jpg', 'B'),
    );

    // user-A のスコープで user-B の参照を消そうとしても消えない。
    await store.deleteRef('user-A', bRef);
    expect(await store.statusOf('user-B', bRef), ImageAssetStatus.present);

    // 自分の参照は消える。
    await store.deleteRef('user-A', aRef);
    expect(await store.statusOf('user-A', aRef), ImageAssetStatus.missing);
  });

  group('owner 分離: 別 owner の参照は解決自体を拒否する（負テスト, item9）', () {
    late String aRef;
    setUp(() async {
      aRef = await store.import(
        ownerId: 'user-A',
        category: ImageCategory.ticket,
        source: makeSource('a.jpg', 'SECRET-A'),
      );
    });

    test('resolveOwned は別 owner スコープでは例外で拒否する', () {
      // user-B のスコープで user-A の参照を解決しようとすると拒否される。
      expect(
        () => store.resolveOwned('user-B', aRef),
        throwsA(isA<ImageAccessException>()),
      );
    });

    test('tryResolveOwned は別 owner では null（ファイルに到達しない）', () {
      expect(store.tryResolveOwned('user-B', aRef), isNull);
      // 自分のスコープなら解決できる（対照）。
      expect(store.resolveOwned('user-A', aRef).existsSync(), isTrue);
    });

    test('statusOf は別 owner では missing（存在を漏らさない）', () async {
      expect(await store.statusOf('user-B', aRef), ImageAssetStatus.missing);
    });

    test('deleteRef は別 owner では何もしない（他人のファイルを消さない）', () async {
      await store.deleteRef('user-B', aRef);
      expect(await store.statusOf('user-A', aRef), ImageAssetStatus.present);
    });
  });

  group('不正参照の拒否（パストラバーサル・絶対パス・区切り）', () {
    test('.. を含む参照は拒否する', () {
      expect(
        () => store.resolveOwned('user-A', 'images/user-A/memory/../../x.jpg'),
        throwsA(isA<ImageAccessException>()),
      );
      expect(
        store.tryResolveOwned('user-A', 'images/user-A/../user-B/t/x.jpg'),
        isNull,
      );
    });

    test('絶対パスは拒否する（旧絶対パス参照も解決しない）', () {
      final abs = p.join(srcDir.path, 'legacy.jpg');
      expect(
        () => store.resolveOwned('user-A', abs),
        throwsA(isA<ImageAccessException>()),
      );
      expect(store.tryResolveOwned('user-A', abs), isNull);
    });

    test('Windows 区切り(バックスラッシュ)を含む参照は拒否する', () {
      expect(
        store.tryResolveOwned('user-A', r'images\user-A\memory\x.jpg'),
        isNull,
      );
    });

    test('images 接頭辞・owner 不一致・浅い参照は拒否する', () {
      expect(
        store.tryResolveOwned('user-A', 'evil/user-A/memory/x.jpg'),
        isNull,
      );
      expect(
        store.tryResolveOwned('user-A', 'images/user-B/memory/x.jpg'),
        isNull,
      );
      expect(store.tryResolveOwned('user-A', 'images/user-A/x.jpg'), isNull);
      expect(store.tryResolveOwned('user-A', ''), isNull);
    });
  });

  test('purgeOwner は対象 owner の画像だけ削除する', () async {
    final aRef = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.memoryPhoto,
      source: makeSource('a.jpg', 'A'),
    );
    final bRef = await store.import(
      ownerId: 'user-B',
      category: ImageCategory.memoryPhoto,
      source: makeSource('b.jpg', 'B'),
    );
    await store.purgeOwner('user-A');
    expect(await store.statusOf('user-A', aRef), ImageAssetStatus.missing);
    expect(await store.statusOf('user-B', bRef), ImageAssetStatus.present);
  });

  test('cleanupOrphans は keep 以外を削除し、別 owner は触らない', () async {
    final keep = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.memoryPhoto,
      source: makeSource('keep.jpg', 'K'),
    );
    final orphan = await store.import(
      ownerId: 'user-A',
      category: ImageCategory.memoryPhoto,
      source: makeSource('orphan.jpg', 'O'),
    );
    final other = await store.import(
      ownerId: 'user-B',
      category: ImageCategory.memoryPhoto,
      source: makeSource('other.jpg', 'X'),
    );

    await store.cleanupOrphans('user-A', {keep});

    expect(await store.statusOf('user-A', keep), ImageAssetStatus.present);
    expect(await store.statusOf('user-A', orphan), ImageAssetStatus.missing);
    // 別 owner は保持。
    expect(await store.statusOf('user-B', other), ImageAssetStatus.present);
  });
}
