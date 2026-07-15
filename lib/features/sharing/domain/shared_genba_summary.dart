import 'genba_permission.dart';
import 'share.dart';

/// 共有された現場のサマリ（一覧表示用の軽量モデル・追加要件 §1）。
///
/// 自分が [role]（editor/viewer）で共有された現場の最小情報。現場本体は自分の
/// ローカル owner スコープには入らない（サーバー権威）ため、一覧表示にはこの
/// サマリを使い、詳細/編集は別途サーバーから取得する（D-239）。
class SharedGenbaSummary {
  const SharedGenbaSummary({
    required this.genbaId,
    required this.title,
    this.artistName,
    this.eventDate,
    required this.role,
  });

  final String genbaId;
  final String title;
  final String? artistName;
  final DateTime? eventDate;

  /// 自分の共有権限（editor / viewer）。
  final ShareRole role;

  /// この共有現場に対する自分の権限（owner ではないので isShared=true）。
  GenbaPermission get permission =>
      genbaPermissionFor(isOwner: false, memberRole: role);
}
