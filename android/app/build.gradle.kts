import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing properties for release builds
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.example.ai_mentor_coach"
    compileSdk = flutter.compileSdkVersion
    // Override NDK version to match plugin requirements (backward compatible)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable desugaring to support Java 8+ APIs on older Android versions
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.ai_mentor_coach"
        // You can update the following values to match your application needs.
        // For more information, see: https://docs.flutter.dev/to/review-gradle-config.
        // IMPORTANT: minSdk 31 (Android 12) required by LiteRT LLM library
        minSdk = 31
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // OPTIMIZATION: Enable code shrinking and resource optimization
            isMinifyEnabled = true
            isShrinkResources = true

            // Use ProGuard for code optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Use release signing config if available, otherwise fall back to debug
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // FIXED: Add Google Play Core library to resolve R8 missing classes error
    // This is required for Flutter's Play Store integration features
    implementation("com.google.android.play:core:1.10.3")

    // Core library desugaring for Java 8+ API support on older Android versions
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // LiteRT LLM (Google AI Edge) for on-device AI inference (Gemma 3-1B-IT)
    // This is the new official library replacing MediaPipe LLM Inference API
    // Used by Google's official AI Edge Gallery demo app
    // https://github.com/google-ai-edge/ai-edge-gallery
    // Version: 0.0.0-alpha05 (matches Google's AI Edge Gallery)
    implementation("com.google.ai.edge.litertlm:litertlm:0.0.0-alpha05")

    // Kotlin reflection (required by LiteRT LLM for tool management)
    implementation("org.jetbrains.kotlin:kotlin-reflect:1.9.0")

    // AndroidX Media for MediaSession (Bluetooth headset button handling for hands-free voice)
    implementation("androidx.media:media:1.7.0")

    // Android Auto Car App Library for hands-free voice todo creation while driving
    implementation("androidx.car.app:app:1.4.0")
}