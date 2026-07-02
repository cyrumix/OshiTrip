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
abstract interface class DraftStore {
  Future<String?> load(String key);
  Future<void> save(String key, String payloadJson);
  Future<void> clear(String key);
}

class DriftDraftStore implements DraftStore {
  DriftDraftStore(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<String?> load(String key) async {
    final row = await (_db.select(_db.formDrafts)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.payload;
  }

  @override
  Future<void> save(String key, String payloadJson) =>
      _db.into(_db.formDrafts).insertOnConflictUpdate(
            FormDraftsCompanion.insert(
              key: key,
              payload: payloadJson,
              updatedAt: _clock.now().toUtc().toIso8601String(),
            ),
          );

  @override
  Future<void> clear(String key) =>
      (_db.delete(_db.formDrafts)..where((t) => t.key.equals(key))).go();
}
