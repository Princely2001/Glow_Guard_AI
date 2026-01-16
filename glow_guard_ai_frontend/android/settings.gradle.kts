pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        properties.getProperty("flutter.sdk")
            ?: throw GradleException("flutter.sdk not set in local.properties")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // ✅ Firebase google-services plugin version (IMPORTANT)
    plugins {
        id("com.google.gms.google-services") version "4.4.4" // Change 4.4.2 to 4.4.4
    }
}

plugins {
    // ✅ Flutter plugin loader (required)
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // ✅ Keep these (versions can stay as yours)
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

dependencyResolutionManagement {
    // Change the mode here:
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "glowguard_app"
include(":app")
