// ignore_for_file: constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

/// 画像アップロード状態（ローカル参照とリモート保存を型で区別する, §12）。
///
/// 思い出写真の [PhotoUploadStatus] と同じ意味だが、hero 画像・推し画像など
/// 用途をまたいで共有できるよう core に置く。JSON 値はサーバー列の
/// `*_upload_status`（'local_only' 等）と一致させる。
enum ImageUploadStatus {
  @JsonValue('local_only')
  localOnly,
  @JsonValue('queued')
  queued,
  @JsonValue('uploaded')
  uploaded,
  @JsonValue('failed')
  failed,
}

extension ImageUploadStatusJson on ImageUploadStatus {
  /// サーバー列 / Drift 列と一致する snake_case 文字列。
  String get wire => switch (this) {
        ImageUploadStatus.localOnly => 'local_only',
        ImageUploadStatus.queued => 'queued',
        ImageUploadStatus.uploaded => 'uploaded',
        ImageUploadStatus.failed => 'failed',
      };

  static ImageUploadStatus fromWire(String? value) => switch (value) {
        'queued' => ImageUploadStatus.queued,
        'uploaded' => ImageUploadStatus.uploaded,
        'failed' => ImageUploadStatus.failed,
        _ => ImageUploadStatus.localOnly,
      };
}
