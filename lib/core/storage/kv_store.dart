import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../time/clock.dart';

/// 端末ローカルの Key-Value 保存（チュートリアル完了・テーマ設定など）。
abstract interface class KvStore {
  Future<String?> get(String key);
  Future<void> put(String key, String value);
  Future<void> remove(String key);
  Stream<String?> watch(String key);
}

/// よく使うキー。
class KvKeys {
  static const tutorialDone = 'tutorial_done';
  static const themeMode = 'theme_mode';
  static const demoUser = 'demo_user';

  /// ユーザーが選んだ推しカラー（#RRGGBB）。アクセント（罫線・リング・
  /// プレースホルダー）のフォールバックに使う（design-spec §2/§11）。
  ///
  /// 推しカラーは個人化設定のため owner 単位で保存する（C-01）。ログアウト・
  /// ユーザー切替時に別ユーザーへ色設定が漏れないよう、キーへ ownerId を
  /// 含める。owner 不明の旧キー `oshi_accent_color`（R7 中間版のみ）は
  /// 推測で誰かへ帰属させず読み捨てる（D-44 と同方針）。
  static String oshiAccentColorFor(String ownerId) =>
      'oshi_accent_color.$ownerId';

  /// サーバー側アカウント削除は成功したが、ローカルデータの物理削除が
  /// 未完了の owner_id を記録する（C-01）。値が残っている間は、次回起動時に
  /// ローカル purge を安全に再試行する。端末単位の運用フラグのため owner
  /// 分離の対象外（[AppKvs] に保存）。
  static const pendingAccountPurge = 'pending_account_purge';
}

class DriftKvStore implements KvStore {
  DriftKvStore(this._db);

  final AppDatabase _db;

  @override
  Future<String?> get(String key) async {
    final row = await (_db.select(_db.appKvs)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> put(String key, String value) => _db
      .into(_db.appKvs)
      .insertOnConflictUpdate(AppKvsCompanion.insert(key: key, value: value));

  @override
  Future<void> remove(String key) =>
      (_db.delete(_db.appKvs)..where((t) => t.key.equals(key))).go();

  @override
  Stream<String?> watch(String key) =>
      (_db.select(_db.appKvs)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);
}

/// フォーム下書きの保存（自動保存・再開、§2.1）。
///
/// owner_id を必須引数にする（C-01）。下書きは端末内のみで完結するデータ
/// だが、同一端末で複数ユーザーが使う可能性を踏まえ、他ownerの下書きを
/// 読み書きできないようにする。
abstract interface class DraftStore {
  Future<String?> load(String ownerId, String key);
  Future<void> save(String ownerId, String key, String payloadJson);
  Future<void> clear(String ownerId, String key);
}

class DriftDraftStore implements DraftStore {
  DriftDraftStore(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<String?> load(String ownerId, String key) async {
    final row = await (_db.select(_db.formDrafts)
          ..where((t) => t.ownerId.equals(ownerId) & t.key.equals(key)))
        .getSingleOrNull();
    return row?.payload;
  }

  @override
  Future<void> save(String ownerId, String key, String payloadJson) =>
      _db.into(_db.formDrafts).insertOnConflictUpdate(
            FormDraftsCompanion.insert(
              ownerId: ownerId,
              key: key,
              payload: payloadJson,
              updatedAt: _clock.now().toUtc().toIso8601String(),
            ),
          );

  @override
  Future<void> clear(String ownerId, String key) => (_db.delete(_db.formDrafts)
        ..where((t) => t.ownerId.equals(ownerId) & t.key.equals(key)))
      .go();
}
