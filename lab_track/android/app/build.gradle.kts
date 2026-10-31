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
    // Pinned NDK version — must match ANDROID_NDK_VERSION in .github/workflows/build-apk.yml
    // This prevents Gradle from downloading NDK on-the-fly during CI/CD builds.
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.labtrack.lab_track"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val cmKeystorePath = System.getenv("CM_KEYSTORE_PATH") ?: System.getenv("KEYSTORE_PATH")
            if (cmKeystorePath != null && file(cmKeystorePath).exists()) {
                storeFile = file(cmKeystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD") ?: System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS") ?: System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD") ?: System.getenv("KEY_PASSWORD")
            } else {
                val appKeystore = file("debug.keystore")
                if (appKeystore.exists()) {
                    storeFile = appKeystore
                    storePassword = "android"
                    keyAlias = "androiddebugkey"
                    keyPassword = "android"
                }
            }
        }
        getByName("debug") {
            val appKeystore = file("debug.keystore")
            if (appKeystore.exists()) {
                storeFile = appKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            // Signs with Codemagic keystore if provided, or defaults to debug.keystore matching Firebase SHA-1
            signingConfig = signingConfigs.getByName("release")
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
