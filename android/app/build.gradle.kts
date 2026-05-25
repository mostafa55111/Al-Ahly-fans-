plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // يجب أن يطابق تطبيق الأندرويد في Firebase Console + google-services.json
    namespace = "com.mostafa.gomhor_ahly"
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
        // يجب مطابقة package_name لتطبيق أندرويد في google-services.json (مشروع Firebase نفسه).
        // للنشر بمعرّف com.mostafa.gomhor_ahly: أضف التطبيق في Firebase Console ثم حدّث google-services.json.
        applicationId = "com.example.gomhor_alahly_clean_new"
        // FFmpeg Kit يتطلب minSdk 24+؛ نرفع الحد الأدنى عند الحاجة فوق قيمة Flutter الافتراضية.
        minSdk = maxOf(flutter.minSdkVersion, 24)
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
