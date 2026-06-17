plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.zapbook"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "space.zapbook.app"
        val suffix = System.getenv("APP_ID_SUFFIX")
        if (suffix != null) {
            applicationId += suffix
        }
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
        }
        resources {
            excludes += "assets/flutter_assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w100.ttf"
            excludes += "assets/flutter_assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w200.ttf"
            excludes += "assets/flutter_assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w300.ttf"
            excludes += "assets/flutter_assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w400.ttf"
            excludes += "assets/flutter_assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w500.ttf"
            excludes += "assets/flutter_assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w600.ttf"
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
