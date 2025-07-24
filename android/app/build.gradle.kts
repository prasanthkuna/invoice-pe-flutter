plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.invoicepe.invoice_pe_app"
    compileSdk = 35  // TESLA FIX: Update to SDK 35 for plugin compatibility
    ndkVersion = "27.0.12077973"

    // Enable BuildConfig feature for custom fields (Codemagic fix)
    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.invoicepe.invoice_pe_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.

        // Set explicit SDK versions for better device compatibility
        minSdk = 21  // Android 5.0 (covers 99%+ of devices)
        targetSdk = 34  // Android 14 (stable and widely supported)
        // compileSdk set above to 35 for plugin compatibility

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            isDebuggable = true
            isMinifyEnabled = false
            // Enhanced logging for real device testing
            buildConfigField("boolean", "ENABLE_SMART_LOGGING", "true")
            buildConfigField("String", "LOG_LEVEL", "\"debug\"")
        }

        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isDebuggable = false
            // Smart logging for production
            buildConfigField("boolean", "ENABLE_SMART_LOGGING", "true")
            buildConfigField("String", "LOG_LEVEL", "\"warning\"")
        }
    }
}

flutter {
    source = "../.."
}
