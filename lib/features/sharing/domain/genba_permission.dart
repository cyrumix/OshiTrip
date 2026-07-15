import 'share.dart';

/// 現場に対する自分のアクセス種別（追加要件 §1/§4/§5）。
///
/// - [owner]: 現場所有者。全操作可。
/// - [editor]: 共有された共同編集者。内容の編集可・削除/オーナー変更/メンバー管理不可。
/// - [viewer]: 共有された閲覧者。閲覧のみ。
/// - [none]: 未共有（アクセス不可）。
enum GenbaAccessRole { owner, editor, viewer, none }

/// 現場のアクセス権限（UIのボタン表示/非活性やサーバー経路選択の判断に使う純粋値）。
///
/// サーバー側の強制（RLS / `apply_shared_mutation` / owner 限定 RPC, 0031）と一致させる。
/// クライアントのこの判定はあくまで UX（見せない/押させない）であり、最終的な可否は
/// 常にサーバーが決める。
class GenbaPermission {
  const GenbaPermission(this.role);

  final GenbaAccessRole role;

  /// 共有現場（owner ではないが閲覧/編集できる）。「共有」バッジ表示に使う。
  bool get isShared =>
      role == GenbaAccessRole.editor || role == GenbaAccessRole.viewer;

  /// 現場本体・子データを閲覧できる。
  bool get canView => role != GenbaAccessRole.none;

  /// 共同編集対象（Todo/持ち物/チケット/交通/宿泊/計画/メモ/思い出等）を編集できる。
  bool get canEditContent =>
      role == GenbaAccessRole.owner || role == GenbaAccessRole.editor;

  /// 共有メンバーの追加・削除・権限変更・招待URL発行/無効化ができる（owner のみ）。
  bool get canManageMembers => role == GenbaAccessRole.owner;

  /// 現場を削除できる（owner のみ）。
  bool get canDeleteGenba => role == GenbaAccessRole.owner;

  /// オーナーを変更できる（owner のみ）。
  bool get canChangeOwner => role == GenbaAccessRole.owner;

  /// 権限の日本語ラベル。
  String get label => switch (role) {
        GenbaAccessRole.owner => 'オーナー',
        GenbaAccessRole.editor => '編集可',
        GenbaAccessRole.viewer => '閲覧のみ',
        GenbaAccessRole.none => '未共有',
      };
}

/// owner 判定と共有ロールから [GenbaAccessRole] を決める。
///
/// owner なら常に owner。owner でなければ、共有された [memberRole]（editor/viewer）を
/// 使う。共有されていなければ none。
GenbaAccessRole genbaAccessRole({
  required bool isOwner,
  ShareRole? memberRole,
}) {
  if (isOwner) return GenbaAccessRole.owner;
  return switch (memberRole) {
    ShareRole.editor => GenbaAccessRole.editor,
    ShareRole.viewer => GenbaAccessRole.viewer,
    ShareRole.owner => GenbaAccessRole.owner,
    null => GenbaAccessRole.none,
  };
}

/// 便宜コンストラクタ（owner 判定＋共有ロール → 権限）。
GenbaPermission genbaPermissionFor({
  required bool isOwner,
  ShareRole? memberRole,
}) =>
    GenbaPermission(genbaAccessRole(isOwner: isOwner, memberRole: memberRole));
