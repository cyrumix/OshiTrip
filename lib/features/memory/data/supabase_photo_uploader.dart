import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/time/clock.dart';
import '../domain/memory.dart';
import '../domain/memory_repository.dart';

/// Supabase Storage への写真アップロード実装（境界実装）。
///
/// バケット `memory-photos` はマイグレーションで private として作成し、
/// パス `{owner_id}/{genba_id}/{photo_id}` の所有者のみ読み書き可能な
/// Storage ポリシーを適用する（ADR-0008）。
/// バックグラウンドアップロード・再試行キューは後続範囲
/// （docs/follow-up-work.md）。
class SupabasePhotoUploader implements MemoryPhotoUploader {
  SupabasePhotoUploader(this._client, this._clock);

  static const bucket = 'memory-photos';

  final SupabaseClient _client;
  final Clock _clock;

  String _objectPath(MemoryPhoto photo) =>
      '${photo.ownerId}/${photo.genbaId}/${photo.id}.jpg';

  @override
  Future<Result<MemoryPhoto>> upload(MemoryPhoto photo) async {
    final localPath = photo.localPath;
    if (localPath == null) {
      return const Err(ValidationFailure('アップロードする端末内の写真がありません'));
    }
    final file = File(localPath);
    if (!file.existsSync()) {
      return const Err(NotFoundFailure(message: '端末内の写真が見つかりません'));
    }
    try {
      final path = _objectPath(photo);
      await _client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return Ok(
        photo.copyWith(
          storagePath: path,
          uploadStatus: PhotoUploadStatus.uploaded,
          updatedAt: _clock.now().toUtc(),
        ),
      );
    } on StorageException catch (e) {
      if (e.statusCode == '403') {
        return Err(PermissionFailure(cause: e));
      }
      return Err(NetworkFailure(message: '写真のアップロードに失敗しました', cause: e));
    } catch (e) {
      return Err(UnknownFailure(cause: e));
    }
  }

  @override
  Future<Result<Uri>> signedUrl(MemoryPhoto photo) async {
    final path = photo.storagePath;
    if (path == null) {
      return const Err(NotFoundFailure(message: 'アップロード済みの写真がありません'));
    }
    try {
      final url = await _client.storage
          .from(bucket)
          .createSignedUrl(path, 60 * 60); // 1時間
      return Ok(Uri.parse(url));
    } on StorageException catch (e) {
      return Err(PermissionFailure(cause: e));
    } catch (e) {
      return Err(UnknownFailure(cause: e));
    }
  }
}
