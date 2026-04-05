/// نظام حقن الاعتماديات المحسّن
///
/// يستخدم هذا الملف نمط Service Locator لإدارة الاعتماديات
/// مما يسمح بفصل الكود وسهولة الاختبار
library;

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/datasources/video_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/reels/data/repositories/video_repository_impl.dart';
import 'package:gomhor_alahly_clean_new/features/reels/domain/repositories/video_repository.dart';
import 'package:gomhor_alahly_clean_new/features/reels/presentation/bloc/reels_bloc.dart';
import 'package:gomhor_alahly_clean_new/features/matches/data/datasources/best_player_remote_data_source.dart';
import 'package:gomhor_alahly_clean_new/features/matches/presentation/bloc/matches_bloc.dart';
import 'package:gomhor_alahly_clean_new/core/services/cloudinary_service.dart';


/// الحصول على نسخة من Service Locator
final getIt = GetIt.instance;

/// إعداد حقن الاعتماديات
Future<void> setupServiceLocator() async {
  // ===== Core Services =====

  
  // ===== Firebase Services =====

  /// تسجيل Firebase Auth
  getIt.registerSingleton<FirebaseAuth>(
    FirebaseAuth.instance,
  );

  /// تسجيل Firebase Realtime Database
  getIt.registerSingleton<FirebaseDatabase>(
    FirebaseDatabase.instance,
  );

  /// تسجيل Cloudinary Service
  getIt.registerSingleton<CloudinaryService>(
    CloudinaryService(),
  );

  /// تسجيل Firebase Storage
  getIt.registerSingleton<FirebaseStorage>(
    FirebaseStorage.instance,
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
  final currentUserId = getIt<FirebaseAuth>().currentUser?.uid ?? '';

  /// تسجيل Cloudinary Service (temporarily disabled)
  // getIt.registerLazySingleton<CloudinaryService>(
  //   () => CloudinaryService(),
  // );

  /// تسجيل Reels Feature
  getIt.registerLazySingleton<VideoRemoteDataSource>(
    () => VideoRemoteDataSource(),
  );
  getIt.registerLazySingleton<VideoRepository>(
    () => VideoRepositoryImpl(
      remoteDataSource: getIt<VideoRemoteDataSource>(),
      cloudinaryService: getIt<CloudinaryService>(),
    ),
  );

  /// تسجيل Matches Feature
  getIt.registerLazySingleton<BestPlayerRemoteDataSource>(
    () => BestPlayerRemoteDataSource(),
  );
  getIt.registerFactory<MatchesBloc>(
    () => MatchesBloc(dataSource: getIt<BestPlayerRemoteDataSource>()),
  );

  // ===== BLoC Services =====

  /// تسجيل BLoCs
  getIt.registerFactory<ReelsBloc>(
    () => ReelsBloc(videoRepository: getIt<VideoRepository>()),
  );
  getIt.registerFactory<MatchesBloc>(
    () => MatchesBloc(dataSource: getIt<BestPlayerRemoteDataSource>()),
  );
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
bool isServiceRegistered<T extends Object>() {
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
