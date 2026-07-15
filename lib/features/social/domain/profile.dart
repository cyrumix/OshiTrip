import '../../../core/error/result.dart';

/// 簡易プロフィール（追加要件 §1）。共有メンバー一覧・招待参加画面・フレンド
/// 一覧で表示する。最低限は表示名とアイコンを優先する。
///
/// 本人のみ編集でき（サーバー RLS `profiles_*_self`）、可視範囲は本人・承認済み
/// フレンド・同一現場の共有メンバー・`searchable=true` に限る（`can_view_profile`）。
class Profile {
  const Profile({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.favoriteName,
    this.acceptsFriendRequests = true,
    this.searchable = false,
    this.friendCode = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String? bio;

  /// アカウント固有の一意なフレンドコード（サーバー採番, 例: `OSHI-7K3P-Q9A2`）。
  /// これを相手に伝えると、相手は searchable でなくてもコードで申請できる。
  final String friendCode;

  /// 推し名または推しカテゴリ（任意）。
  final String? favoriteName;

  /// フレンド申請を受け付けるか。
  final bool acceptsFriendRequests;

  /// 検索可能にするか（既定 false = 無制限検索に晒さない, §7）。
  final bool searchable;

  final DateTime createdAt;
  final DateTime updatedAt;

  Profile copyWith({
    String? displayName,
    String? avatarUrl,
    String? bio,
    String? favoriteName,
    bool? acceptsFriendRequests,
    bool? searchable,
    DateTime? updatedAt,
  }) =>
      Profile(
        userId: userId,
        displayName: displayName ?? this.displayName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        favoriteName: favoriteName ?? this.favoriteName,
        acceptsFriendRequests:
            acceptsFriendRequests ?? this.acceptsFriendRequests,
        searchable: searchable ?? this.searchable,
        friendCode: friendCode,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

/// 表示名・ひとこと・推し名の上限（サーバー CHECK と一致する純粋関数）。
const int kDisplayNameMaxLength = 40;
const int kBioMaxLength = 140;
const int kFavoriteNameMaxLength = 40;

/// プロフィール入力の不変条件。問題があれば理由、無ければ null。
///
/// - 表示名は 1〜[kDisplayNameMaxLength] 文字（必須）。
/// - ひとこと・推し名は任意だが上限を超えない。
String? profileInvariantError({
  required String displayName,
  String? bio,
  String? favoriteName,
}) {
  final name = displayName.trim();
  if (name.isEmpty) {
    return '表示名を入力してください';
  }
  if (name.length > kDisplayNameMaxLength) {
    return '表示名は$kDisplayNameMaxLength文字以内で入力してください';
  }
  if (bio != null && bio.length > kBioMaxLength) {
    return 'ひとことは$kBioMaxLength文字以内で入力してください';
  }
  if (favoriteName != null && favoriteName.length > kFavoriteNameMaxLength) {
    return '推し名は$kFavoriteNameMaxLength文字以内で入力してください';
  }
  return null;
}

/// プロフィールのリポジトリ抽象（本人編集＋可視範囲内の参照）。
///
/// 複数ユーザーをまたぐサーバー権威データのため offline 同期には載せず、
/// Supabase 実装は RLS（`profiles_*_self` / `can_view_profile`）に従う。
abstract interface class ProfileRepository {
  /// 自分のプロフィールを取得する（未設定なら null）。
  Future<Result<Profile?>> fetchMyProfile();

  /// 自分のプロフィールを作成・更新する（本人限定）。
  Future<Result<Profile>> upsertMyProfile({
    required String displayName,
    String? bio,
    String? favoriteName,
    required bool acceptsFriendRequests,
    required bool searchable,
  });

  /// 指定ユーザーのプロフィールを取得する（可視範囲外なら null）。
  Future<Result<Profile?>> fetchProfile(String userId);

  /// 複数ユーザーのプロフィールをまとめて取得する（メンバー/フレンド一覧表示用）。
  Future<Result<Map<String, Profile>>> fetchProfiles(List<String> userIds);
}
