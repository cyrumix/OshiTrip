import 'bootstrap.dart';
import 'core/config/env.dart';

/// 汎用エントリ（`-t` を指定しない `flutter run`/IDEのデフォルト実行用）。
///
/// **development 専用に固定**する。`main_development.dart` と同一内容であり、
/// staging/production では使わない（`--flavor staging|production` の
/// native applicationId/bundle id と組み合わせた場合は、常に
/// `core/config/flavor_guard.dart` の起動時ガードが拒否する。
/// `test/core/env_flavor_test.dart` で回帰確認している）。
/// staging/production を明示的に起動する場合は必ず対応する
/// `main_staging.dart`/`main_production.dart` を `-t` で指定すること
/// （README.md「flavor（環境）とビルドコマンドの対応」参照）。
Future<void> main() => bootstrap(Flavor.development);
