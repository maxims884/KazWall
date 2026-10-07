import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Ключ подписи для Google Play: android/key.properties (в репозиторий не попадает), см. README
val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "kz.black13.kazwall"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Нужно пакету уведомлений
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        minSdk = 23
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Два приложения из одного кода: flutter build appbundle --flavor kaz|uzb.
    // Название и иконка каждого — в src/<flavor>/res, остальные отличия — в lib/config.dart
    flavorDimensions += "country"
    productFlavors {
        create("kaz") {
            dimension = "country"
            applicationId = "kz.black13.kazwall"
            manifestPlaceholders["admobAppId"] = "ca-app-pub-2230097402282612~3805993929"
        }
        create("uzb") {
            dimension = "country"
            applicationId = "uz.black13.uzbwall"
            // Пока это тестовый идентификатор Google: перед публикацией вписать свой из AdMob
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        }
    }

    signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("release") {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Пока своего ключа нет, сборка подписывается отладочным, чтобы работал flutter run --release
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
