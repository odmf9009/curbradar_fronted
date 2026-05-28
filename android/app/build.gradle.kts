import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin handles the Kotlin integration.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProps = Properties()
val keyPropsFile = rootProject.file("key.properties")
if (keyPropsFile.exists()) keyProps.load(keyPropsFile.inputStream())

android {
    namespace = "com.venturesflstudio.curb_radar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProps["keyAlias"]?.toString() ?: ""
            keyPassword = keyProps["keyPassword"]?.toString() ?: ""
            val storeFileProp = keyProps["storeFile"]?.toString()
            if (storeFileProp != null) {
                storeFile = file(storeFileProp)
            }
            storePassword = keyProps["storePassword"]?.toString() ?: ""
        }
    }

    defaultConfig {
        applicationId = "com.venturesflstudio.curb_radar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }

    dependencies {
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    }
}

flutter {
    source = "../.."
}
