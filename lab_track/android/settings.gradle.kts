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
                val pathSdk = (System.getenv("PATH") ?: "")
                    .split(java.io.File.pathSeparator)
                    .map { java.io.File(it) }
                    .firstNotNullOfOrNull { dir ->
                        if (java.io.File(dir, "flutter.bat").exists() || java.io.File(dir, "flutter").exists()) {
                            dir.parentFile?.takeIf { java.io.File(it, "packages/flutter_tools").exists() }?.absolutePath
                        } else null
                    }
                val candidatePaths = listOfNotNull(
                    pathSdk,
                    System.getenv("FLUTTER_ROOT"),
                    System.getenv("FLUTTER_HOME"),
                    "C:\\flutter",
                    "C:\\src\\flutter",
                    "${System.getProperty("user.home")}\\flutter",
                    "${System.getProperty("user.home")}\\AppData\\Local\\flutter",
                    "${System.getProperty("user.home")}\\scoop\\apps\\flutter\\current",
                    "D:\\flutter",
                    "D:\\src\\flutter"
                )
                sdkPath = candidatePaths.firstOrNull { file(it).exists() }
            }
            require(sdkPath != null && file(sdkPath).exists()) {
                "Flutter SDK could not be found. Please ensure 'flutter.sdk' in 'local.properties' points to your valid Flutter installation path or set the FLUTTER_ROOT environment variable."
            }
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
    id("com.android.application") version "8.7.3" apply false
    id("com.android.library") version "8.7.3" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version "4.4.2" apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.3.0" apply false
}

include(":app")
