plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gomhor_alahly_clean_new"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    configurations.all {
    resolutionStrategy {
        force("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")
    }
    } 

    compileOptions {
        // تفعيل الـ Desugaring لحل مشكلة الإشعارات
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.gomhor_alahly_clean_new"
        minSdk = flutter.minSdkVersion // مهم جداً للإشعارات
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }
}

dependencies {
    // المكتبات المطلوبة لنظام KTS
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
    implementation("androidx.multidex:multidex:2.0.1")
}
