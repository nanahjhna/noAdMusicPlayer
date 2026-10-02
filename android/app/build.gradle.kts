import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

// key.properties 파일 읽기 (android/key.properties)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.han.noAdMusicPlayer"

    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    // buildTypes보다 먼저 정의되어야 함
    signingConfigs {
        create("release") {
            if (keystoreProperties.isNotEmpty()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")

                val storeFilePath = keystoreProperties.getProperty("storeFile")
                if (storeFilePath != null) {
                    // key.properties의 위치(android/) 기준으로 app/upload-key.jks를 올바르게 찾아감
                    storeFile = project.file(storeFilePath)
                }
            }
        }
    }

    defaultConfig {
        applicationId = "com.han.noAdMusicPlayer"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            // key.properties 정보가 있을 때만 release 서명 적용
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

flutter {
    source = "../.."
}