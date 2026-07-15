# Deep Link（招待URL）配置手順

招待URL `https://oshitrip.app/invite/{token}` を開いたときにアプリの参加確認画面
（`/invite/:token` → `InviteJoinScreen`）へ遷移させるための設定。Phase 5 / D-237。

Flutter 側は go_router（`MaterialApp.router` + `routerConfig`）が受信 URI のパス
`/invite/{token}` をそのままルーティングするため、追加の Dart 実装は不要。必要なのは
**ネイティブの App Links / Universal Links 設定**と、ドメイン側の**検証ファイル配置**。

> 本リポジトリ環境（Docker/実機/署名鍵なし）では**未検証**。実デバイス・実ドメインでの
> 動作確認が必要。

## 1. ドメイン側に検証ファイルを配置（HTTPS・リダイレクトなし・`Content-Type: application/json`）

- iOS: `https://oshitrip.app/.well-known/apple-app-site-association`
  - このリポジトリの `deeplink/apple-app-site-association` を基に、`REPLACE_TEAM_ID` を
    Apple Developer の Team ID へ置換する。拡張子なしで配置する。
- Android: `https://oshitrip.app/.well-known/assetlinks.json`
  - `deeplink/assetlinks.json` の `REPLACE_*_SHA256_FINGERPRINT` を、リリース署名鍵の
    SHA256 フィンガープリント（`keytool -list -v -keystore <release.keystore>`）へ置換する。

## 2. iOS（Xcode）

- `ios/Runner/Runner.entitlements`（本リポジトリに追加済み）を Xcode の
  **Signing & Capabilities → Associated Domains** で有効化し、`applinks:oshitrip.app` を確認。
- ビルド設定 `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` を各 Configuration に設定
  （Xcode で Capability を追加すると自動設定される）。

## 3. Android

- `android/app/src/main/AndroidManifest.xml`（本リポジトリに追加済み）に
  `https://oshitrip.app/invite` の `VIEW`/`BROWSABLE` intent-filter（`autoVerify="true"`）を追加済み。
- リリースビルドの署名鍵の SHA256 を assetlinks.json に反映し、Play Console の App signing 鍵を使う
  場合はそちらの SHA256 も追加する。

## 4. 動作確認（実機）

- Android: `adb shell am start -a android.intent.action.VIEW -d "https://oshitrip.app/invite/TESTTOKEN" app.oshitrip.mobile.dev`
- iOS: メモアプリ等に URL を貼り、タップしてアプリが参加画面を開くことを確認。
- 未ログイン時は `/login?from=/invite/{token}` へ退避し、ログイン後に参加画面へ復帰する
  （`resolveAuthRedirect`、`test/app/auth_redirect_test.dart`）。
