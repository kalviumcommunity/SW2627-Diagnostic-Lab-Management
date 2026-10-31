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
        minSdk = 23
        targetSdk = 35
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
            val customKeystore = cmKeystorePath?.let { file(it) }
            val localKeystore = listOf(
                file("debug.keystore"),
                file("${project.projectDir}/debug.keystore"),
                file("${project.rootDir}/app/debug.keystore")
            ).firstOrNull { it.exists() }

            if (customKeystore != null && customKeystore.exists()) {
                storeFile = customKeystore
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD") ?: System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS") ?: System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD") ?: System.getenv("KEY_PASSWORD")
            } else if (localKeystore != null) {
                storeFile = localKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
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
