import 'dart:io';

/// 暗号化DBセットアップの型付き失敗（H-03）。[stage] で失敗段階を表す。
///
/// - 'key-missing': 暗号化DBが存在するのに鍵が無い（鍵消失）。鍵を再生成して
///   上書きしてはならない（既存DBを開けなくなるため）。
/// - 'key-read': 既存鍵の読み取り（Secure Storage/Keychain）に失敗。
/// - 'key-create': 鍵の取得/生成（Secure Storage/Keychain 書込み）に失敗。
/// - 'verify-failed': 既存暗号化DBが鍵で開けない（誤鍵/破損）。鍵を上書きしない。
/// - 'export' / 'verify': 平文→暗号化の移行に失敗（平文は温存される）。
/// - 'cleanup' / 'restore' / 'finalize': 残存平文/backup の掃除・復元・確定
///   （rename/delete）に失敗。
/// - 'prepare' / 'resolve' / 'open': SQLCipher準備・解決全体・DB open の失敗
///   （bootstrap 側で付与）。
class EncryptionSetupException implements Exception {
  const EncryptionSetupException(this.stage, [this.cause]);
  final String stage;
  final Object? cause;
  @override
  String toString() => 'EncryptionSetupException($stage)';
}

/// 解決結果: 開くべき暗号化DBファイルと鍵。
typedef EncryptedDbResolution = ({File encrypted, String key});

/// 平文DB・暗号化DB・.migrating・.premigration.bak の全組合せを状態機械として
/// 安全に解決する（H-03 item1/2）。
///
/// 不変条件:
/// - 既存暗号化DBは必ず「正しい鍵で verify」してから使う。verify 失敗・鍵消失は
///   鍵を再生成・上書きせず [EncryptionSetupException] を投げる。
/// - 検証済み暗号化DBが真実になるまで平文を削除しない（未検証平文は消さない）。
/// - 暗号化DB確定直後の電源断（平文/backup 残存）でも、暗号化DBを verify して
///   から残存を安全に掃除する。
/// - 中断した .migrating（未確定の部分成果物）は常に破棄する。
///
/// 実際の暗号化・検証は [export]/[verify]（device の SQLCipher）に注入し、本体は
/// ファイル操作の choreography のみ（プラグイン非依存・host テスト可能）。
class EncryptedDbResolver {
  EncryptedDbResolver({
    required this.readExistingKey,
    required this.getOrCreateKey,
    required this.export,
    required this.verify,
  });

  /// 既存鍵の読み取り（生成しない）。無ければ null。
  final Future<String?> Function() readExistingKey;

  /// 鍵の取得（無ければ生成）。新規暗号化・移行時のみ使う。
  final Future<String> Function() getOrCreateKey;

  /// 平文 [src] を鍵付き暗号化DB [target] へ書き出す。
  final Future<void> Function(File src, File target, String key) export;

  /// 暗号化DB [f] が鍵で開けるか検証する。
  final Future<bool> Function(File f, String key) verify;

  Future<EncryptedDbResolution> resolve({
    required File plaintext,
    required File encrypted,
  }) async {
    final migrating = File('${encrypted.path}.migrating');
    final backup = File('${plaintext.path}.premigration.bak');

    // 中断した移行の部分成果物は常に破棄（未確定なので破棄安全）。
    _fileOp('cleanup', () {
      if (migrating.existsSync()) migrating.deleteSync();
    });

    // (A) 暗号化DBが存在する: 必ず検証してから使う。
    if (encrypted.existsSync()) {
      final key = await _readKey();
      if (key == null) {
        // 鍵消失。再生成すると既存DBを開けなくするため、明示エラーで停止。
        throw const EncryptionSetupException('key-missing');
      }
      final ok = await _verify(encrypted, key);
      if (!ok) {
        // 誤鍵/破損。鍵を上書き・再生成しない。
        throw const EncryptionSetupException('verify-failed');
      }
      // 暗号化DBが真実。確定直後の電源断で残った平文/backup を安全に掃除。
      _fileOp('cleanup', () {
        if (plaintext.existsSync()) plaintext.deleteSync();
        if (backup.existsSync()) backup.deleteSync();
      });
      return (encrypted: encrypted, key: key);
    }

    // (B) 暗号化DBが無い。移行完了後に E が失われ backup だけ残る異常時は、
    //     平文を backup から復元してから移行し直す。
    if (!plaintext.existsSync() && backup.existsSync()) {
      _fileOp('restore', () => backup.renameSync(plaintext.path));
    }

    // 新規暗号化・移行では鍵を取得（無ければ生成）。
    final key = await _createKey();

    // (C) 平文があれば暗号化DBへ一度だけ移行する。
    if (plaintext.existsSync()) {
      try {
        await export(plaintext, migrating, key);
      } catch (e) {
        _fileOp('cleanup', () {
          if (migrating.existsSync()) migrating.deleteSync();
        });
        throw EncryptionSetupException('export', e); // 平文温存
      }
      final ok = await _verify(migrating, key);
      if (!ok) {
        _fileOp('cleanup', () {
          if (migrating.existsSync()) migrating.deleteSync();
        });
        throw const EncryptionSetupException('verify'); // 平文温存
      }
      _fileOp('finalize', () {
        migrating.renameSync(encrypted.path); // atomic 確定
        // 確定後、平文を backup 経由で削除（この間の電源断でも E は残る）。
        if (backup.existsSync()) backup.deleteSync();
        plaintext.renameSync(backup.path);
        backup.deleteSync();
      });
      return (encrypted: encrypted, key: key);
    }

    // (D) 新規インストール: 空の暗号化DBを開く（open 時に鍵で作成される）。
    return (encrypted: encrypted, key: key);
  }

  /// Secure Storage の読み取り失敗を型付き例外へ変換する（鍵消失＝null は別扱い）。
  Future<String?> _readKey() async {
    try {
      return await readExistingKey();
    } catch (e) {
      throw EncryptionSetupException('key-read', e);
    }
  }

  Future<String> _createKey() async {
    try {
      return await getOrCreateKey();
    } catch (e) {
      throw EncryptionSetupException('key-create', e);
    }
  }

  /// verify 自体が例外を投げても「検証失敗」に倒す（誤鍵/破損と同じ扱い）。
  Future<bool> _verify(File f, String key) async {
    try {
      return await verify(f, key);
    } catch (_) {
      return false;
    }
  }

  /// ファイル操作（rename/delete）の失敗を段階付き例外へ変換する。
  void _fileOp(String stage, void Function() op) {
    try {
      op();
    } on EncryptionSetupException {
      rethrow;
    } catch (e) {
      throw EncryptionSetupException(stage, e);
    }
  }
}
