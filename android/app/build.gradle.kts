import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load signing configuration
val keystoreProperties = Properties()
val keystorePropertiesFile = file("../key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    println("ELON DEBUG: Keystore file found at: ${keystorePropertiesFile.absolutePath}")
    println("ELON DEBUG: Store file: ${keystoreProperties["storeFile"]}")
} else {
    println("ELON DEBUG: Keystore file NOT found at: ${keystorePropertiesFile.absolutePath}")
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

    // ELON-STYLE SIGNING CONFIGURATION
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            } else {
                // Fallback to debug signing if keystore not found
                keyAlias = "androiddebugkey"
                keyPassword = "android"
                storeFile = file("debug.keystore")
                storePassword = "android"
            }
        }
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

    // ELON-STANDARD: Asset compression and optimization
    packagingOptions {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module",
                "kotlin/**",
                "**/*.kotlin_metadata"
            )
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".demo"
            versionNameSuffix = "-demo"
            isDebuggable = true
            isMinifyEnabled = false
            // Enhanced logging for demo builds
            buildConfigField("boolean", "ENABLE_SMART_LOGGING", "true")
            buildConfigField("String", "LOG_LEVEL", "\"debug\"")
            buildConfigField("boolean", "MOCK_PAYMENT_MODE", "true")
        }

        release {
            // ELON-STYLE: Use proper release signing
            signingConfig = signingConfigs.getByName("release")

            // PHASE 3: NUCLEAR OPTIMIZATION - Enable all optimizations
            isMinifyEnabled = true      // Enable ProGuard/R8
            isShrinkResources = true    // Enable resource shrinking
            isDebuggable = false

            // ProGuard configuration for maximum optimization
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Smart logging for production
            buildConfigField("boolean", "ENABLE_SMART_LOGGING", "true")
            buildConfigField("String", "LOG_LEVEL", "\"info\"")
            buildConfigField("boolean", "MOCK_PAYMENT_MODE", "true")
        }
    }
}

flutter {
    source = "../.."
}
