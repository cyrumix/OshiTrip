import 'bootstrap.dart';
import 'core/config/env.dart';

/// 既定エントリ（`flutter run` 用）。development として起動する。
Future<void> main() => bootstrap(Flavor.development);
