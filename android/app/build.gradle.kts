plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "jp.co.gaxi.oshi.oshi_expedition"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "jp.co.gaxi.oshi.oshi_expedition"
        // 最低OS: Android 8.0 / API 26（ADR-0006。通知チャンネル対応のため）
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 環境分離（ADR-0007）: development / staging / production
    flavorDimensions += "env"
    productFlavors {
        create("development") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            // resValue() は最新 AGP で非対応 → AndroidManifest.xml で設定
            // resValue("string", "app_name", "推し活遠征管理（dev）")
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".stg"
            // resValue("string", "app_name", "推し活遠征管理（stg）")
        }
        create("production") {
            dimension = "env"
            // resValue("string", "app_name", "推し活遠征管理")
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
