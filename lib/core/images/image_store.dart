import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// 画像の用途区分（H-04）。用途別ディレクトリへ分離し、機密度も区別する。
enum ImageCategory { memoryPhoto, genbaHero, oshiImage, ticket, itinerarySpot }

extension ImageCategoryX on ImageCategory {
  String get dirName => switch (this) {
        ImageCategory.memoryPhoto => 'memory',
        ImageCategory.genbaHero => 'hero',
        ImageCategory.oshiImage => 'oshi',
        ImageCategory.ticket => 'ticket',
        ImageCategory.itinerarySpot => 'itinerary_spot',
      };

  /// 最も機密度の高い区分（チケット画像）。バックアップ除外・ログ除外・
  /// ヒーロー／思い出表紙への流用禁止の対象（§7.3/§7.8, ADR-0008）。
  bool get isSensitive => this == ImageCategory.ticket;
}

/// 画像アセットの型付き状態（絶対一時パスに依存しない, H-04）。
///
/// - [present]: 実ファイルが存在し読み取り可能。
/// - [missing]: 参照は妥当だがファイルが無い。
/// - [inaccessible]: 権限不足・ロック・種別不整合等で読めない（端末ロック時の
///   iOS ファイル保護など）。`FileSystemException` をこの状態へ変換する。
enum ImageAssetStatus { present, missing, inaccessible }

/// 不正な画像参照アクセス（別owner・絶対パス・パストラバーサル）を示す例外。
class ImageAccessException implements Exception {
  const ImageAccessException(this.message);
  final String message;
  @override
  String toString() => 'ImageAccessException: $message';
}

/// 画像の耐久保存に失敗したことを示す例外（コピー失敗・バックアップ除外失敗）。
/// 失敗を成功扱いにしないため、呼び出し側は StorageFailure 等へ変換して UI へ
/// 返し、生成途中のファイルは削除済みであることを前提にできる。
class ImageStorageException implements Exception {
  const ImageStorageException(this.message, [this.cause]);
  final String message;
  final Object? cause;
  @override
  String toString() => 'ImageStorageException: $message';
}

/// 機密画像を OS バックアップ対象から除外する処理（H-04）。
/// iOS は NSURLIsExcludedFromBackupKey（MethodChannel 経由）。Android は
/// allowBackup=false を採用するため通常呼ばれない。テストでは fake を注入する。
typedef BackupExcluder = Future<void> Function(String absolutePath);

/// 選択画像をアプリ管理領域へ耐久保存するストア（H-04）。
///
/// - owner 別・用途別ディレクトリに、推測困難なファイル名で保存する。
/// - コピーは一時ファイル→rename の atomic write。
/// - DB には絶対一時パスではなく「アプリ管理上の相対参照」を保存する。
/// - 参照は `images/<owner>/<category>/<uuid>.<ext>`（区切りは常に '/'）。
/// - すべての解決/状態/削除は owner スコープ必須。別 owner 参照・絶対パス・
///   パストラバーサル（`..`）は拒否する（C-01/H-04）。
class ImageStore {
  ImageStore(this._baseDir, {BackupExcluder? backupExcluder})
      : _backupExcluder = backupExcluder;

  /// アプリ管理のベースディレクトリ（本番: getApplicationDocumentsDirectory）。
  final Directory _baseDir;
  final BackupExcluder? _backupExcluder;

  static const _uuid = Uuid();
  static const _root = 'images';

  Directory _ownerCategoryDir(String ownerId, ImageCategory category) =>
      Directory(p.join(_baseDir.path, _root, ownerId, category.dirName));

  String _refFor(String ownerId, ImageCategory category, String fileName) =>
      '$_root/$ownerId/${category.dirName}/$fileName';

  /// [source] をアプリ管理領域へコピーし、相対参照を返す（atomic write）。
  ///
  /// 機密区分（チケット）はコピー後に OS バックアップ除外を行い、除外に失敗した
  /// 場合は「確定保存できなかった」とみなして生成ファイルを削除し
  /// [ImageStorageException] を投げる（失敗を成功扱いにしない, H-04）。
  Future<String> import({
    required String ownerId,
    required ImageCategory category,
    required File source,
  }) async {
    final dir = _ownerCategoryDir(ownerId, category);
    final ext = p.extension(source.path);
    final fileName = '${_uuid.v4()}$ext';
    final dest = File(p.join(dir.path, fileName));
    final tmp = File('${dest.path}.tmp');

    // 1) コピー（tmp→rename の atomic write）。失敗したら中間物を消す。
    try {
      await dir.create(recursive: true);
      if (await tmp.exists()) await tmp.delete();
      await source.copy(tmp.path);
      await tmp.rename(dest.path);
    } catch (e) {
      await _bestEffortDelete(tmp);
      await _bestEffortDelete(dest);
      throw ImageStorageException('画像の保存に失敗しました', e);
    }

    // 2) 機密画像はバックアップ除外まで成功して初めて確定保存とみなす。
    if (category.isSensitive && _backupExcluder != null) {
      try {
        await _backupExcluder(dest.path);
      } catch (e) {
        // 除外できないなら流出リスクが残るため確定保存しない。生成物を消す。
        await _bestEffortDelete(dest);
        throw ImageStorageException('画像をバックアップ対象から除外できませんでした', e);
      }
    }
    return _refFor(ownerId, category, fileName);
  }

  Future<void> _bestEffortDelete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // 後片付けの失敗は握りつぶす（元の失敗を優先して伝える）。
    }
  }

  /// [ownerId] スコープで参照を実ファイルへ解決する。別owner・絶対パス・
  /// パストラバーサルは [ImageAccessException] で拒否する（旧絶対パスも拒否）。
  File resolveOwned(String ownerId, String ref) {
    _validateOwnedRef(ownerId, ref);
    return File(p.joinAll([_baseDir.path, ...ref.split('/')]));
  }

  /// 表示用の安全な解決。無効・別owner・欠損は null を返す（例外を投げない）。
  File? tryResolveOwned(String ownerId, String ref) {
    if (!_isValidOwnedRef(ownerId, ref)) return null;
    return File(p.joinAll([_baseDir.path, ...ref.split('/')]));
  }

  /// 参照の型付き状態を返す。`FileSystemException`（権限不足・ロック等）は
  /// 例外を投げず [ImageAssetStatus.inaccessible] へ変換する（H-04 item3）。
  Future<ImageAssetStatus> statusOf(String ownerId, String ref) async {
    if (!_isValidOwnedRef(ownerId, ref)) return ImageAssetStatus.missing;
    final file = File(p.joinAll([_baseDir.path, ...ref.split('/')]));
    try {
      if (await file.exists()) return ImageAssetStatus.present;
      // ファイル位置にディレクトリ等が存在する＝読めない（不整合/アクセス不能）。
      final type = await FileSystemEntity.type(file.path);
      return type == FileSystemEntityType.notFound
          ? ImageAssetStatus.missing
          : ImageAssetStatus.inaccessible;
    } on FileSystemException {
      return ImageAssetStatus.inaccessible;
    }
  }

  /// [statusOf] の同期版（判定規則は同一）。UI の build 中に「表示できない
  /// 理由」を読み込み待ちのちらつきなしで確定させるために使う（R7 / §12）。
  /// stat 相当の軽量な問い合わせのみで、画像本体は読み込まない。
  ImageAssetStatus statusOfSync(String ownerId, String ref) {
    if (!_isValidOwnedRef(ownerId, ref)) return ImageAssetStatus.missing;
    final file = File(p.joinAll([_baseDir.path, ...ref.split('/')]));
    try {
      if (file.existsSync()) return ImageAssetStatus.present;
      final type = FileSystemEntity.typeSync(file.path);
      return type == FileSystemEntityType.notFound
          ? ImageAssetStatus.missing
          : ImageAssetStatus.inaccessible;
    } on FileSystemException {
      return ImageAssetStatus.inaccessible;
    }
  }

  /// [ownerId] に属する有効な参照のみ削除する。無効・別owner は何もしない。
  Future<void> deleteRef(String ownerId, String ref) async {
    if (!_isValidOwnedRef(ownerId, ref)) return;
    await _bestEffortDelete(
      File(p.joinAll([_baseDir.path, ...ref.split('/')])),
    );
  }

  void _validateOwnedRef(String ownerId, String ref) {
    if (!_isValidOwnedRef(ownerId, ref)) {
      throw const ImageAccessException('不正または別ユーザーの画像参照です');
    }
  }

  bool _isValidOwnedRef(String ownerId, String ref) {
    if (ref.isEmpty || p.isAbsolute(ref)) return false;
    if (ref.contains('\\')) return false; // Windows 区切りは使わない
    final parts = ref.split('/');
    if (parts.length < 4) return false;
    if (parts.any((s) => s.isEmpty || s == '.' || s == '..')) return false;
    return parts[0] == _root && parts[1] == ownerId;
  }

  /// [ownerId] の全画像を削除する（アカウント削除時, §15.2）。
  Future<void> purgeOwner(String ownerId) async {
    final dir = Directory(p.join(_baseDir.path, _root, ownerId));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// [ownerId] のディレクトリ配下で、[keepRefs] に無いファイルを削除する
  /// （レコード削除・画像差替え後の孤立ファイル清掃）。別 owner は対象外。
  Future<void> cleanupOrphans(String ownerId, Set<String> keepRefs) async {
    final dir = Directory(p.join(_baseDir.path, _root, ownerId));
    if (!await dir.exists()) return;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      if (entity.path.endsWith('.tmp')) {
        await entity.delete(); // 中断した import の残骸
        continue;
      }
      final rel = p.relative(entity.path, from: _baseDir.path);
      final ref = p.split(rel).join('/');
      if (!keepRefs.contains(ref)) await entity.delete();
    }
  }
}
