import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/app/router.dart';

/// 認証・チュートリアル・招待Deep Link の遷移解決（§4.1/§7.8.5, D-237）。
void main() {
  String? resolve(
    String location, {
    bool loading = false,
    bool tutorialDone = true,
    bool signedIn = true,
  }) =>
      resolveAuthRedirect(
        location: location,
        uri: Uri.parse(location),
        loading: loading,
        tutorialDone: tutorialDone,
        signedIn: signedIn,
      );

  test('ローディング中は /splash（既に /splash なら維持）', () {
    expect(resolve('/genba', loading: true), '/splash');
    expect(resolve('/splash', loading: true), isNull);
  });

  test('チュートリアル未完了は /onboarding', () {
    expect(resolve('/', tutorialDone: false), '/onboarding');
    expect(resolve('/onboarding', tutorialDone: false), isNull);
  });

  test('未認証は /login（authルートは維持）', () {
    expect(resolve('/genba', signedIn: false), '/login');
    expect(resolve('/login', signedIn: false), isNull);
  });

  test('未認証で招待Deep Linkは /login?from=<invite> へ退避する', () {
    expect(
      resolve('/invite/abc123', signedIn: false),
      '/login?from=${Uri.encodeComponent('/invite/abc123')}',
    );
  });

  test('認証後、from に退避した招待があればそこへ復帰する', () {
    expect(
      resolveAuthRedirect(
        location: '/login',
        uri: Uri.parse('/login?from=%2Finvite%2Fabc123'),
        loading: false,
        tutorialDone: true,
        signedIn: true,
      ),
      '/invite/abc123',
    );
  });

  test('認証済みで auth ルートは /（from が無い場合）', () {
    expect(resolve('/login'), '/');
    expect(resolve('/splash'), '/');
    expect(resolve('/onboarding'), '/');
  });

  test('from が invite 以外の外部/内部パスは無視して /（オープンリダイレクト防止）', () {
    expect(
      resolveAuthRedirect(
        location: '/login',
        uri: Uri.parse('/login?from=%2Fsettings%2Fdata'),
        loading: false,
        tutorialDone: true,
        signedIn: true,
      ),
      '/',
    );
    expect(
      resolveAuthRedirect(
        location: '/login',
        uri: Uri.parse('/login?from=https%3A%2F%2Fevil.example.com'),
        loading: false,
        tutorialDone: true,
        signedIn: true,
      ),
      '/',
    );
  });

  test('認証済みで通常ルートは素通り（null）', () {
    expect(resolve('/genba/123/members'), isNull);
    expect(resolve('/invite/abc123'), isNull);
  });
}
