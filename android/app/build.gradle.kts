plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ailogos"
    compileSdk = flutter.compileSdkVersion

    // NDK version required by your plugins
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.ailogos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Using debug signing so `flutter run --release` works
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // 🔧 IMPORTANT: use Java 21 since that's what you have installed
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    // 🔧 Tell Gradle/Kotlin toolchain to use Java 21
    kotlin {
        jvmToolchain(21)
    }
}

flutter {
    source = "../.."
}