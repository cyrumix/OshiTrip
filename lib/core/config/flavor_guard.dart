import 'env.dart';

/// [Flavor] と実行中バイナリの applicationId(Android)/bundle id(iOS) の
/// 不一致を検知する（H-01）。
///
/// 判定は接尾辞ではなく **既知の nativeId との完全一致**（許可リスト）で行う。
/// 接尾辞判定（`endsWith('.dev')` 等）は、無関係な別アプリの
/// applicationId/bundle id がたまたま同じ接尾辞を持つ場合や、production が
/// 「.dev/.stg で終わらない任意の文字列」を許してしまう場合に誤って
/// 一致と判定してしまう。既知の値だけを許可することでこれを防ぐ。
///
/// 許可される値は下記のみ（android/app/build.gradle.kts の applicationId +
/// applicationIdSuffix、ios/Flutter/Development・Staging・Production.xcconfig の
/// PRODUCT_BUNDLE_IDENTIFIER と一致させること）:
/// Android / iOS で同じ正式IDを使う。
/// - development: `app.oshitrip.mobile.dev`
/// - staging: `app.oshitrip.mobile.stg`
/// - production: `app.oshitrip.mobile`
class FlavorMismatchException implements Exception {
  const FlavorMismatchException(this.flavor, this.nativeId);

  final Flavor flavor;
  final String nativeId;

  @override
  String toString() =>
      'FlavorMismatchException(flavor: $flavor, nativeId: "$nativeId")';
}

/// flavor ごとに許可される nativeId（Android applicationId / iOS bundle id）
/// の完全一致集合。ここに無い値はすべて拒否する。
const Map<Flavor, Set<String>> allowedNativeIds = {
  Flavor.development: {
    'app.oshitrip.mobile.dev',
  },
  Flavor.staging: {
    'app.oshitrip.mobile.stg',
  },
  Flavor.production: {
    'app.oshitrip.mobile',
  },
};

/// [nativeId]（実行中バイナリの applicationId/bundle id）が [flavor] の
/// 許可リストに完全一致するか判定する純関数（プラットフォーム非依存、単体テスト可）。
bool matchesFlavor(Flavor flavor, String nativeId) =>
    allowedNativeIds[flavor]!.contains(nativeId);

/// [flavor] と [nativeId] が一致することを検証する。不一致なら
/// [FlavorMismatchException] を投げる（呼び出し側は起動を停止させること）。
void assertFlavorMatchesNativeId(Flavor flavor, String nativeId) {
  if (!matchesFlavor(flavor, nativeId)) {
    throw FlavorMismatchException(flavor, nativeId);
  }
}
