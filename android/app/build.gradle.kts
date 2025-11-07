import com.chaquo.python.ChaquopyExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.chaquo.python") // ✅ Chaquopy for Python integration
}

android {
    namespace = "com.example.ailogos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.ailogos"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // ✅ Keep the architectures you need
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions.jvmTarget = "21"
    }
}

/**
 * ✅ Chaquopy configuration
 * Must be OUTSIDE the android { } block
 */
configure<ChaquopyExtension> {
    defaultConfig {
        // 👇 Local Python interpreter (installed on your system)
        buildPython("C:/Users/ahmad/AppData/Local/Programs/Python/Python310/python.exe")

        // ✅ Use pyttsx3 instead of TTS — works offline and compatible with Chaquopy
        pip {
            install("gTTS==2.5.1")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
