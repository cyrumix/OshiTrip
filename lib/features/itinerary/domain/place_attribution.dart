/// 施設データ提供元の帰属（Google Place Details (New) の `attributions[]` に対応。
/// 各要素は `{provider: string, providerUri: string}`。確認: 2026-07-08,
/// developers.google.com/maps/documentation/places/web-service/reference/rest/v1/places）。
///
/// [provider] は表示必須。[providerUri] は「確認付きで開ける**有効な https URL**」
/// だけを保持し、不正スキーム・巨大文字列・欠落・想定外オブジェクトは null にする
/// （帰属表示では provider を出し、providerUri が非 null のときだけ外部導線を出す）。
class PlaceAttribution {
  const PlaceAttribution({required this.provider, this.providerUri});

  final String provider;
  final Uri? providerUri;

  @override
  bool operator ==(Object other) =>
      other is PlaceAttribution &&
      other.provider == provider &&
      other.providerUri == providerUri;

  @override
  int get hashCode => Object.hash(provider, providerUri);
}

const int _kMaxProviderLen = 200;
const int _kMaxUriLen = 2000;

/// HTTP Gateway → Dart の JSON1件（`{provider, providerUri}` または後方互換の
/// 文字列）を安全に [PlaceAttribution] へ変換する。provider が無効（空・非文字列・
/// 巨大）なら null（帰属として採用しない）。
PlaceAttribution? parsePlaceAttribution(Object? raw) {
  String? provider;
  Object? uriRaw;
  if (raw is Map) {
    final p = raw['provider'];
    if (p is String) provider = p;
    uriRaw = raw['providerUri'];
  } else if (raw is String) {
    provider = raw; // 後方互換（文字列のみ）
  } else {
    return null; // 想定外オブジェクトは除外
  }
  if (provider == null) return null;
  final trimmed = provider.trim();
  if (trimmed.isEmpty || trimmed.length > _kMaxProviderLen) return null;
  return PlaceAttribution(
    provider: trimmed,
    providerUri: _safeHttpsUri(uriRaw),
  );
}

/// 帰属配列（JSON の List）を安全に変換する。List 以外は空。
List<PlaceAttribution> parsePlaceAttributions(Object? raw) {
  if (raw is! List) return const [];
  final out = <PlaceAttribution>[];
  for (final item in raw) {
    final a = parsePlaceAttribution(item);
    if (a != null) out.add(a);
  }
  return out;
}

/// 有効な https URL（host あり・長すぎない）だけを返す。それ以外は null。
/// http/javascript/data 等の不正・危険スキームは除外する。
Uri? _safeHttpsUri(Object? raw) {
  if (raw is! String) return null;
  final s = raw.trim();
  if (s.isEmpty || s.length > _kMaxUriLen) return null;
  final uri = Uri.tryParse(s);
  if (uri == null) return null;
  if (uri.scheme.toLowerCase() != 'https') return null;
  if (uri.host.isEmpty) return null;
  return uri;
}
