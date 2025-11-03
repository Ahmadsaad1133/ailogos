android {
    namespace = "com.example.ailogos"
    compileSdk = flutter.compileSdkVersion

    // 🔧 Use the highest NDK version required by your plugins
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Java 11 is perfect
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // Keep Kotlin JVM consistent with Java version
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ailogos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // 🧩 Recommended: declare JVM toolchain explicitly for Kotlin
    kotlin {
        jvmToolchain(11)
    }
}
