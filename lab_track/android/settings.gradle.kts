pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localProperties = file("local.properties")
            if (localProperties.exists()) {
                localProperties.inputStream().use { properties.load(it) }
            }
            var sdkPath = properties.getProperty("flutter.sdk")
            if (sdkPath == null || !file(sdkPath).exists()) {
                sdkPath = System.getenv("FLUTTER_ROOT")
                    ?: System.getenv("FLUTTER_HOME")
            }
            require(sdkPath != null) { "flutter.sdk not set in local.properties or FLUTTER_ROOT environment variable" }
            sdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version "4.4.2" apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
