import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val releaseStoreFile =
    keystoreProperties.getProperty("storeFile")?.let { rootProject.file(it) }

android {
    namespace = "com.lineleapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.lineleapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = releaseStoreFile
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = false
        }
        debug {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

val verifyReleaseSigning by tasks.registering {
    doLast {
        check(keystorePropertiesFile.isFile) {
            "Missing android/key.properties; it is required only for release builds."
        }

        val requiredKeys =
            listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        val missingKeys =
            requiredKeys.filter {
                keystoreProperties.getProperty(it).isNullOrBlank()
            }

        check(missingKeys.isEmpty()) {
            "Missing release-signing properties: ${missingKeys.joinToString()}"
        }
        check(releaseStoreFile?.isFile == true) {
            "The configured release keystore does not exist."
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(verifyReleaseSigning)
}
