/// نظام حقن الاعتماديات المحسّن
/// 
/// يستخدم هذا الملف نمط Service Locator لإدارة الاعتماديات
/// مما يسمح بفصل الكود وسهولة الاختبار
library;

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// الحصول على نسخة من Service Locator
final getIt = GetIt.instance;

/// إعداد حقن الاعتماديات
Future<void> setupServiceLocator() async {
  // ===== Firebase Services =====
  
  /// تسجيل Firebase Auth
  getIt.registerSingleton<FirebaseAuth>(
    FirebaseAuth.instance,
  );

  /// تسجيل Firebase Realtime Database
  getIt.registerSingleton<FirebaseDatabase>(
    FirebaseDatabase.instance,
  );

  /// تسجيل Firebase Storage
  getIt.registerSingleton<FirebaseStorage>(
    FirebaseStorage.instance,
  );

  /// تسجيل Firestore
  getIt.registerSingleton<FirebaseFirestore>(
    FirebaseFirestore.instance,
  );

  // ===== Network Services =====

  /// تسجيل Dio (HTTP Client)
  getIt.registerSingleton<Dio>(
    _createDioClient(),
  );

  /// تسجيل Connectivity
  getIt.registerSingleton<Connectivity>(
    Connectivity(),
  );

  // ===== Local Storage Services =====

  /// تسجيل SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // ===== Repository Services =====
  // يمكن إضافة Repositories هنا

  // ===== Use Case Services =====
  // يمكن إضافة Use Cases هنا

  // ===== BLoC Services =====
  // يمكن إضافة BLoCs هنا
}

/// إنشاء عميل Dio محسّن
Dio _createDioClient() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
      contentType: 'application/json',
    ),
  );

  // إضافة Interceptors
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // يمكن إضافة Headers هنا
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // معالجة الاستجابة الناجحة
        return handler.next(response);
      },
      onError: (error, handler) {
        // معالجة الأخطاء
        return handler.next(error);
      },
    ),
  );

  return dio;
}

/// إعادة تعيين Service Locator (للاختبارات)
void resetServiceLocator() {
  getIt.reset();
}

/// التحقق من تسجيل خدمة معينة
bool isServiceRegistered<T>() {
  return getIt.isRegistered<T>();
}

/// الحصول على خدمة معينة
T getService<T extends Object>() {
  return getIt<T>();
}

/// تسجيل خدمة جديدة
void registerService<T extends Object>(T instance) {
  getIt.registerSingleton<T>(instance);
}

/// تسجيل Factory (لإنشاء نسخة جديدة في كل مرة)
void registerFactory<T extends Object>(
  T Function() factory,
) {
  getIt.registerFactory<T>(factory);
}

/// تسجيل Lazy Singleton (يتم إنشاؤه عند الاستخدام الأول)
void registerLazySingleton<T extends Object>(
  T Function() factory,
) {
  getIt.registerLazySingleton<T>(factory);
}
