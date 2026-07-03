import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerSecureFilesChannel(engineBridge.pluginRegistry)
  }

  /// H-04: チケット画像等の機密ファイルを iCloud/iTunes バックアップから
  /// 除外する（NSURLIsExcludedFromBackupKey）。Dart 側 `oshitrip/secure_files`
  /// チャネルから呼ばれる。
  private func registerSecureFilesChannel(_ registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "SecureFiles") else { return }
    let channel = FlutterMethodChannel(
      name: "oshitrip/secure_files",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup",
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path)
      do {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "exclude_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }
}
