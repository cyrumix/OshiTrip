import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/images/image_store.dart';
import '../../../core/providers.dart';
import '../domain/memory.dart';

final memoryBundleProvider = StreamProvider.family<MemoryBundle, String>(
  (ref, genbaId) => ref.watch(memoryRepositoryProvider).watchByGenbaId(genbaId),
);

/// 思い出入力の操作。テキスト系は自動保存（600msデバウンス）。
///
/// すべて任意入力であり、未入力をエラー扱いしない（§8.2）。
class MemoryEditController
    extends AutoDisposeFamilyAsyncNotifier<void, String> {
  Timer? _debounce;
  MemoryEntry? _pendingEntry;

  String get genbaId => arg;

  @override
  Future<void> build(String arg) async {
    ref.onDispose(() {
      _debounce?.cancel();
      // 破棄時に未保存分を書き切る。
      final pending = _pendingEntry;
      if (pending != null) {
        unawaited(ref.read(memoryRepositoryProvider).upsertEntry(pending));
      }
    });
  }

  Future<MemoryEntry> _currentEntry() async {
    if (_pendingEntry != null) return _pendingEntry!;
    final bundle =
        await ref.read(memoryRepositoryProvider).watchByGenbaId(genbaId).first;
    final existing = bundle.entry;
    if (existing != null) return existing;
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final now = ref.read(clockProvider).now().toUtc();
    return MemoryEntry(
      id: const Uuid().v4(),
      genbaId: genbaId,
      ownerId: owner,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateEntry(
    MemoryEntry Function(MemoryEntry entry) transform,
  ) async {
    final entry = transform(await _currentEntry());
    _pendingEntry = entry;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final toSave = _pendingEntry;
      _pendingEntry = null;
      if (toSave != null) {
        await ref.read(memoryRepositoryProvider).upsertEntry(toSave);
      }
    });
  }

  /// [pickedPath]（ImagePicker の一時パス）をアプリ管理領域へコピーし、
  /// DB には相対参照を保存する（H-04: 一時パスに依存しない耐久保存）。
  ///
  /// [albumCategory]/[subjectType]/[subjectId] を渡すとグッズ・行った場所・
  /// 食べものへ紐づく写真として保存する（§8.4）。保存元は同一テーブルに
  /// 一本化し、画面ごとに画像を複製しない。関連項目の実在検証は Repository が行う。
  Future<Failure?> addPhoto(
    String pickedPath, {
    MemoryAlbumCategory albumCategory = MemoryAlbumCategory.event,
    MemorySubjectType? subjectType,
    String? subjectId,
  }) async {
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    if (owner.isEmpty) return const AuthFailure(message: 'ログインが必要です');
    final now = ref.read(clockProvider).now().toUtc();
    final bundle =
        await ref.read(memoryRepositoryProvider).watchByGenbaId(genbaId).first;
    final String storedRef;
    try {
      storedRef = await ref.read(imageStoreProvider).import(
            ownerId: owner,
            category: ImageCategory.memoryPhoto,
            source: File(pickedPath),
          );
    } catch (e) {
      // 画像コピー失敗は成功扱いにしない（入力は保持されないが DB も汚さない）。
      return StorageFailure(cause: e);
    }
    final photo = MemoryPhoto(
      id: const Uuid().v4(),
      genbaId: genbaId,
      ownerId: owner,
      localPath: storedRef,
      sortOrder: bundle.photos.length,
      albumCategory: albumCategory,
      subjectType: subjectType,
      subjectId: subjectId,
      createdAt: now,
      updatedAt: now,
    );
    final result = await ref.read(memoryRepositoryProvider).addPhoto(photo);
    final failure = result.failureOrNull;
    if (failure != null) {
      // DB 保存に失敗したらコピー済みファイルは孤立するので削除する
      // （owner スコープなので他ユーザーのファイルには触れない）。
      await ref.read(imageStoreProvider).deleteRef(owner, storedRef);
    }
    return failure;
  }

  Future<Failure?> deletePhoto(String id) async {
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    // 物理ファイルも掃除する（DB削除の前に参照を控える）。
    final bundle =
        await ref.read(memoryRepositoryProvider).watchByGenbaId(genbaId).first;
    final target = bundle.photos.where((p) => p.id == id).firstOrNull;
    final result = await ref.read(memoryRepositoryProvider).deletePhoto(id);
    final failure = result.failureOrNull;
    if (failure == null && target?.localPath != null && owner.isNotEmpty) {
      await ref.read(imageStoreProvider).deleteRef(owner, target!.localPath!);
    }
    return failure;
  }

  Future<Failure?> addSetlistItem(String songTitle) async {
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final now = ref.read(clockProvider).now().toUtc();
    final bundle =
        await ref.read(memoryRepositoryProvider).watchByGenbaId(genbaId).first;
    final item = SetlistItem(
      id: const Uuid().v4(),
      genbaId: genbaId,
      ownerId: owner,
      position: bundle.setlist.length + 1,
      songTitle: songTitle,
      createdAt: now,
      updatedAt: now,
    );
    final result =
        await ref.read(memoryRepositoryProvider).upsertSetlistItem(item);
    return result.failureOrNull;
  }

  Future<Failure?> deleteSetlistItem(String id) async {
    final result =
        await ref.read(memoryRepositoryProvider).deleteSetlistItem(id);
    return result.failureOrNull;
  }

  Future<Failure?> addGoodsItem(
    String name, {
    int? price,
    int quantity = 1,
  }) async {
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final now = ref.read(clockProvider).now().toUtc();
    final item = GoodsItem(
      id: const Uuid().v4(),
      genbaId: genbaId,
      ownerId: owner,
      name: name,
      price: price,
      quantity: quantity,
      createdAt: now,
      updatedAt: now,
    );
    final result =
        await ref.read(memoryRepositoryProvider).upsertGoodsItem(item);
    return result.failureOrNull;
  }

  Future<Failure?> deleteGoodsItem(String id) async {
    final result = await ref.read(memoryRepositoryProvider).deleteGoodsItem(id);
    return result.failureOrNull;
  }

  Future<Failure?> addVisitedPlace(String name, String category) async {
    final owner = ref.read(authRepositoryProvider).currentUser?.id ?? '';
    final now = ref.read(clockProvider).now().toUtc();
    final place = VisitedPlace(
      id: const Uuid().v4(),
      genbaId: genbaId,
      ownerId: owner,
      name: name,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
    final result =
        await ref.read(memoryRepositoryProvider).upsertVisitedPlace(place);
    return result.failureOrNull;
  }

  Future<Failure?> deleteVisitedPlace(String id) async {
    final result =
        await ref.read(memoryRepositoryProvider).deleteVisitedPlace(id);
    return result.failureOrNull;
  }

  /// 写真アップロード境界の呼び出し（単発・失敗は failed として記録）。
  Future<Failure?> uploadPhoto(MemoryPhoto photo) async {
    final uploader = ref.read(photoUploaderProvider);
    if (uploader == null) {
      return const ValidationFailure('デモモードでは写真をアップロードできません');
    }
    final repo = ref.read(memoryRepositoryProvider);
    await repo
        .updatePhoto(photo.copyWith(uploadStatus: PhotoUploadStatus.queued));
    final result = await uploader.upload(photo);
    return result.when(
      ok: (uploaded) async {
        await repo.updatePhoto(uploaded);
        return null;
      },
      err: (failure) async {
        await repo.updatePhoto(
          photo.copyWith(uploadStatus: PhotoUploadStatus.failed),
        );
        return failure;
      },
    );
  }
}

final memoryEditControllerProvider = AsyncNotifierProvider.autoDispose
    .family<MemoryEditController, void, String>(MemoryEditController.new);
