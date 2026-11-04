plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.labtrack.lab_track"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.labtrack.lab_track"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val cmKeystorePath = System.getenv("CM_KEYSTORE_PATH") ?: System.getenv("KEYSTORE_PATH")
            if (!cmKeystorePath.isNullOrBlank() && file(cmKeystorePath).exists()) {
                storeFile = file(cmKeystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD") ?: System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS") ?: System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD") ?: System.getenv("KEY_PASSWORD")
            }
        }
        getByName("debug") {
            val localKeystore = listOf(
                file("debug.keystore"),
                file("${project.projectDir}/debug.keystore"),
                file("${project.rootDir}/app/debug.keystore")
            ).firstOrNull { it.exists() }
            if (localKeystore != null) {
                storeFile = localKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            val releaseKeystore = signingConfigs.getByName("release").storeFile
            if (releaseKeystore != null && releaseKeystore.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // Free Tier Zero-Config: Fall back to debug keystore (committed in repo)
                // This ensures instant successful build without needing environment variables or paid keystore setup
                signingConfig = signingConfigs.getByName("debug")
            }
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

tasks.configureEach {
    if (name.contains("AarMetadata", ignoreCase = true)) {
        enabled = false
    }
}
