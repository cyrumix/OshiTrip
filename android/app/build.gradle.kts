import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// リリース署名の安全な注入境界（H-01/M-02）。実鍵はリポジトリに置かない。
// ローカルは android/key.properties（.gitignore済み）、CIはシークレットから
// 同名ファイルを生成して供給する。無ければ development/staging の release は
// debug 署名へフォールバックする（ローカルの `flutter run --release` を壊さない
// ため）が、production の release ビルドは下の signingConfigs ブロックで
// 明示的に拒否する（debug署名のまま本番リリースされることを防ぐ）。
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "app.oshitrip.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.oshitrip.mobile"
        // 最低OS: Android 8.0 / API 26（ADR-0006。通知チャンネル対応のため）
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 環境分離（ADR-0007）: development / staging / production。
    // applicationId 接尾辞（.dev / .stg / 接尾辞なし）は
    // core/config/flavor_guard.dart の起動時検証と規約を共有する（H-01）。
    // アプリ表示名は各 flavor の src/<flavor>/res/values/strings.xml
    // （app_name）で分離する。
    flavorDimensions += "env"
    productFlavors {
        create("development") {
            dimension = "env"
            applicationIdSuffix = ".dev"
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".stg"
        }
        create("production") {
            dimension = "env"
        }
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // 実鍵が無い間は debug 署名にフォールバック。production の
                // assemble/bundle は下のタスクガードで別途拒否される。
                signingConfigs.getByName("debug")
            }
        }
    }
}

// production flavor の release（assembleProductionRelease /
// bundleProductionRelease）は、実署名（android/key.properties または
// CIシークレットから生成した同名ファイル）が無ければタスク実行時に
// 明示的に失敗させる。「Android release で debug 署名を使う現状は
// 本番リリース不可」という状態が、検出不能な成功として通らないための
// 安全弁（H-01）。他 flavor・他 buildType の設定評価には影響しない
// （タスク実行時のみ判定するため development の flutter run 等は妨げない）。
tasks.matching { task ->
    task.name.startsWith("assembleProduction") && task.name.endsWith("Release") ||
        task.name.startsWith("bundleProduction") && task.name.endsWith("Release")
}.configureEach {
    doFirst {
        if (!hasReleaseSigning) {
            throw GradleException(
                "production の release ビルドには実署名が必要です。" +
                    "android/key.properties（.gitignore済み、storeFile/storePassword/" +
                    "keyAlias/keyPassword を記載）を用意するか、CIでシークレットから" +
                    "同名ファイルを生成してください。debug署名のまま本番リリースする" +
                    "ことは禁止しています。",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
