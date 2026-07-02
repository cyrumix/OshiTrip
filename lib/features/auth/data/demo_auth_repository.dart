import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/storage/kv_store.dart';
import '../domain/auth_repository.dart';

/// デモモード（development かつ Supabase 未設定時のみ）のローカル認証。
///
/// UI には常に「デモモード」を明示する（AppUser.isDemo = true）。
/// 本番・staging では bootstrap がこの実装を選択しない（暗黙フォールバック禁止）。
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository(this._kv);

  final KvStore _kv;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _current;
  bool _restored = false;

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final raw = await _kv.get(KvKeys.demoUser);
    if (raw != null) {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _current = AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        isDemo: true,
      );
    }
    _controller.add(_current);
  }

  @override
  Stream<AppUser?> authStateChanges() async* {
    await restore();
    yield _current;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _current;

  Future<Result<AppUser>> _establish(String email) async {
    final user = AppUser(id: const Uuid().v4(), email: email, isDemo: true);
    await _kv.put(
      KvKeys.demoUser,
      jsonEncode({'id': user.id, 'email': user.email}),
    );
    _current = user;
    _controller.add(user);
    return Ok(user);
  }

  @override
  Future<Result<AppUser>> signUp({
    required String email,
    required String password,
  }) async {
    if (!email.contains('@')) {
      return const Err(ValidationFailure('メールアドレスの形式が正しくありません'));
    }
    if (password.length < 6) {
      return const Err(ValidationFailure('パスワードは6文字以上にしてください'));
    }
    return _establish(email);
  }

  @override
  Future<Result<AppUser>> signIn({
    required String email,
    required String password,
  }) async {
    // デモモードでは端末内で完結するため、任意の資格情報でログイン可能。
    return signUp(email: email, password: password);
  }

  @override
  Future<Result<void>> signOut() async {
    await _kv.remove(KvKeys.demoUser);
    _current = null;
    _controller.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    return const Err(
      ValidationFailure('デモモードではパスワード再設定は利用できません'),
    );
  }
}
