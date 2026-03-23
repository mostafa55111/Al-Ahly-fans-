/// معالج الأخطاء المحسّن
/// 
/// يوفر هذا الملف طرقاً موحدة لمعالجة جميع أنواع الأخطاء في التطبيق
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';

/// فئة معالج الأخطاء
class ErrorHandler {
  /// معالجة الأخطاء وتحويلها إلى AppException
  static AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('Error Handler: $error');
    debugPrint('Stack Trace: $stackTrace');

    // إذا كان الخطأ بالفعل AppException، أرجعه مباشرة
    if (error is AppException) {
      return error;
    }

    // معالجة أخطاء Dio
    if (error is DioException) {
      return _handleDioError(error, stackTrace);
    }

    // معالجة أخطاء Firebase
    if (error.toString().contains('firebase')) {
      return _handleFirebaseError(error, stackTrace);
    }

    // معالجة الأخطاء الأخرى
    return UnknownException(
      message: error.toString(),
      originalException: error,
      stackTrace: stackTrace,
    );
  }

  /// معالجة أخطاء Dio
  static AppException _handleDioError(
    DioException error,
    StackTrace? stackTrace,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return TimeoutException(
          message: 'انتهت مهلة الاتصال - يرجى المحاولة مرة أخرى',
          originalException: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.connectionError:
        return NoInternetException(
          message: 'فشل الاتصال - تحقق من اتصالك بالإنترنت',
          originalException: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(
          error.response?.statusCode,
          error.response?.data,
          error,
          stackTrace,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'خطأ في شهادة الأمان',
          code: 'BAD_CERTIFICATE',
          originalException: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NoInternetException(
            originalException: error,
            stackTrace: stackTrace,
          );
        }
        return UnknownException(
          message: error.message ?? 'حدث خطأ غير متوقع',
          originalException: error,
          stackTrace: stackTrace,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          message: 'تم إلغاء الطلب',
          code: 'REQUEST_CANCELLED',
          originalException: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// معالجة الاستجابات غير الناجحة
  static AppException _handleBadResponse(
    int? statusCode,
    dynamic responseData,
    DioException error,
    StackTrace? stackTrace,
  ) {
    final message = _getErrorMessage(responseData);

    switch (statusCode) {
      case 400:
        return BadRequestException(
          message: message,
          originalException: error,
          stackTrace: stackTrace,
        );

      case 401:
        return UnauthorizedException(
          message: message,
          originalException: error,
          stackTrace: stackTrace,
        );

      case 403:
        return ForbiddenException(
          message: message,
          originalException: error,
          stackTrace: stackTrace,
        );

      case 404:
        return NotFoundException(
          message: message,
          originalException: error,
          stackTrace: stackTrace,
        );

      case 500:
        return InternalServerException(
          message: message,
          originalException: error,
          stackTrace: stackTrace,
        );

      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          originalException: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// معالجة أخطاء Firebase
  static AppException _handleFirebaseError(
    dynamic error,
    StackTrace? stackTrace,
  ) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('auth')) {
      return AuthenticationException(
        message: 'خطأ في المصادقة',
        originalException: error,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('database')) {
      return DatabaseException(
        message: 'خطأ في قاعدة البيانات',
        originalException: error,
        stackTrace: stackTrace,
      );
    }

    if (errorString.contains('storage')) {
      return StorageException(
        message: 'خطأ في التخزين',
        originalException: error,
        stackTrace: stackTrace,
      );
    }

    return FirebaseException(
      message: 'خطأ في Firebase',
      originalException: error,
      stackTrace: stackTrace,
    );
  }

  /// استخراج رسالة الخطأ من استجابة الخادم
  static String _getErrorMessage(dynamic responseData) {
    if (responseData == null) {
      return 'حدث خطأ في الخادم';
    }

    if (responseData is Map) {
      // محاولة الحصول على رسالة الخطأ من عدة مفاتيح محتملة
      return responseData['message'] ??
          responseData['error'] ??
          responseData['msg'] ??
          'حدث خطأ غير متوقع';
    }

    if (responseData is String) {
      return responseData;
    }

    return 'حدث خطأ غير متوقع';
  }

  /// الحصول على رسالة الخطأ الملائمة للمستخدم
  static String getUserFriendlyMessage(AppException exception) {
    return exception.message;
  }

  /// تسجيل الخطأ (للتطوير والتصحيح)
  static void logError(
    AppException exception, {
    bool includeStackTrace = true,
  }) {
    if (kDebugMode) {
      debugPrint('=== Error Log ===');
      debugPrint('Type: ${exception.runtimeType}');
      debugPrint('Code: ${exception.code}');
      debugPrint('Message: ${exception.message}');
      if (includeStackTrace && exception.stackTrace != null) {
        debugPrint('Stack Trace:\n${exception.stackTrace}');
      }
      debugPrint('==================');
    }
  }

  /// إرسال الخطأ إلى خدمة التتبع (مثل Sentry)
  static Future<void> reportError(AppException exception) async {
    // يمكن إضافة خدمة تتبع الأخطاء هنا
    // مثل Sentry أو Firebase Crash Reporting
    debugPrint('Error reported: ${exception.message}');
  }
}

/// امتداد للأخطاء العامة
extension ErrorHandling on Object {
  /// تحويل أي خطأ إلى AppException
  AppException toAppException([StackTrace? stackTrace]) {
    return ErrorHandler.handleError(this, stackTrace);
  }
}
