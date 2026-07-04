import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/local_data_scope.dart';
import '../../../core/providers.dart';
import '../../../core/storage/kv_store.dart';

/// ユーザーの推しカラー設定（design-spec §2/§11・端末保存）。
///
/// 値は #RRGGBB（null = 未設定）。プリセット外のカスタム値も保存できる。
/// 用途はアクセント（現場カード罫線・アバターリング・プレースホルダー）の
/// フォールバックに限定し、本文や重要操作の可読性を壊さない（§2）。
///
/// 個人化設定のため **owner 単位** で保存する（C-01）。[localDataScopeProvider]
/// を watch しているため、ログイン・ログアウト・ユーザー切替で自動的に
/// 再構築され、別ユーザーの色設定が漏れて表示されることはない。
/// 未認証・認証復元中は未設定（null = テーマPrimary）として扱う。
class OshiColorNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final scope = ref.watch(localDataScopeProvider);
    final ownerId = scope.ownerIdOrNull;
    if (ownerId == null) return null;
    final value = await ref
        .watch(kvStoreProvider)
        .get(KvKeys.oshiAccentColorFor(ownerId));
    // 保存値が壊れている場合は未設定として扱う（外部データを信頼しない）。
    if (value == null || AppTheme.tryParseHexColor(value) == null) return null;
    return value;
  }

  /// #RRGGBB を保存する。解析できない値・未認証時は保存せず false を返す。
  Future<bool> setHex(String hex) async {
    final ownerId = ref.read(localDataScopeProvider).ownerIdOrNull;
    if (ownerId == null) return false;
    final normalized = hex.startsWith('#') ? hex : '#$hex';
    if (AppTheme.tryParseHexColor(normalized) == null) return false;
    await ref
        .read(kvStoreProvider)
        .put(KvKeys.oshiAccentColorFor(ownerId), normalized);
    state = AsyncData(normalized);
    return true;
  }

  Future<void> clear() async {
    final ownerId = ref.read(localDataScopeProvider).ownerIdOrNull;
    if (ownerId == null) return;
    await ref.read(kvStoreProvider).remove(KvKeys.oshiAccentColorFor(ownerId));
    state = const AsyncData(null);
  }
}

final oshiColorProvider =
    AsyncNotifierProvider<OshiColorNotifier, String?>(OshiColorNotifier.new);

/// ユーザー推しカラーを [Color] として解決する（未設定はテーマPrimary）。
Color resolveUserAccent(WidgetRef ref, ColorScheme scheme) {
  final hex = ref.watch(oshiColorProvider).valueOrNull;
  return AppTheme.accentFromHex(hex, scheme);
}
