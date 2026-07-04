import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'image_store.dart';

/// 端末内画像参照の型付き状態（present / missing / inaccessible）を
/// UI から watch するための provider（design-spec §12 / H-04 item3・R7）。
///
/// - missing: ファイルが存在しない（端末から削除された・参照が不正）。
/// - inaccessible: 権限不足・端末ロック等で読み取れない（再試行の余地あり）。
///
/// 判定は stat 相当の同期チェック（[ImageStore.statusOfSync]）で行い、
/// 読み込み待ちのちらつきなしに build 中へ確定させる。家族キーは record
/// （構造等価）。`ref.invalidate` で再判定（再試行）できる。
final imageAssetStatusProvider = Provider.autoDispose
    .family<ImageAssetStatus, ({String ownerId, String ref})>(
  (ref, key) =>
      ref.watch(imageStoreProvider).statusOfSync(key.ownerId, key.ref),
);
