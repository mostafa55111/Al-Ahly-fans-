/// استثناءات التطبيق المخصصة
///
/// تحتوي هذه الملف على جميع أنواع الاستثناءات المخصصة للتطبيق
/// مما يسمح بمعالجة الأخطاء بشكل أكثر دقة وتفصيلاً
library;

/// الفئة الأساسية لجميع استثناءات التطبيق
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

// ===== Network Exceptions =====

/// استثناء الشبكة العام
class NetworkException extends AppException {
  NetworkException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'NETWORK_ERROR',
        );
}

/// استثناء انقطاع الاتصال
class NoInternetException extends NetworkException {
  NoInternetException({
    super.message = 'لا يوجد اتصال بالإنترنت',
    super.originalException,
    super.stackTrace,
  }) : super(
          code: 'NO_INTERNET',
        );
}

/// استثناء انتهاء مهلة الاتصال
class TimeoutException extends NetworkException {
  TimeoutException({
    super.message = 'انتهت مهلة الاتصال',
    super.originalException,
    super.stackTrace,
  }) : super(
          code: 'TIMEOUT',
        );
}

/// استثناء فشل الاتصال
class ConnectionFailedException extends NetworkException {
  ConnectionFailedException({
    super.message = 'فشل الاتصال',
    super.originalException,
    super.stackTrace,
  }) : super(
          code: 'CONNECTION_FAILED',
        );
}

// ===== Server Exceptions =====

/// استثناء الخادم العام
class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required super.message,
    this.statusCode,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'SERVER_ERROR',
        );
}

/// استثناء خطأ 400
class BadRequestException extends ServerException {
  BadRequestException({
    super.message = 'طلب غير صحيح',
    super.originalException,
    super.stackTrace,
  }) : super(
          statusCode: 400,
          code: 'BAD_REQUEST',
        );
}

/// استثناء خطأ 401 (غير مصرح)
class UnauthorizedException extends ServerException {
  UnauthorizedException({
    super.message = 'غير مصرح - يرجى تسجيل الدخول',
    super.originalException,
    super.stackTrace,
  }) : super(
          statusCode: 401,
          code: 'UNAUTHORIZED',
        );
}

/// استثناء خطأ 403 (محظور)
class ForbiddenException extends ServerException {
  ForbiddenException({
    super.message = 'محظور - ليس لديك صلاحيات كافية',
    super.originalException,
    super.stackTrace,
  }) : super(
          statusCode: 403,
          code: 'FORBIDDEN',
        );
}

/// استثناء خطأ 404 (غير موجود)
class NotFoundException extends ServerException {
  NotFoundException({
    super.message = 'المورد غير موجود',
    super.originalException,
    super.stackTrace,
  }) : super(
          statusCode: 404,
          code: 'NOT_FOUND',
        );
}

/// استثناء خطأ 500 (خطأ في الخادم)
class InternalServerException extends ServerException {
  InternalServerException({
    super.message = 'خطأ في الخادم',
    super.originalException,
    super.stackTrace,
  }) : super(
          statusCode: 500,
          code: 'INTERNAL_SERVER_ERROR',
        );
}

// ===== Firebase Exceptions =====

/// استثناء Firebase العام
class FirebaseException extends AppException {
  FirebaseException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'FIREBASE_ERROR',
        );
}

/// استثناء فشل المصادقة
class AuthenticationException extends FirebaseException {
  AuthenticationException({
    super.message = 'فشل المصادقة',
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'AUTH_ERROR',
        );
}

/// استثناء فشل قاعدة البيانات
class DatabaseException extends FirebaseException {
  DatabaseException({
    super.message = 'خطأ في قاعدة البيانات',
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'DATABASE_ERROR',
        );
}

/// استثناء فشل التخزين
class StorageException extends FirebaseException {
  StorageException({
    super.message = 'خطأ في التخزين',
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'STORAGE_ERROR',
        );
}

// ===== Data Exceptions =====

/// استثناء البيانات العام
class DataException extends AppException {
  DataException({
    required super.message,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'DATA_ERROR',
        );
}

/// استثناء البيانات الفارغة
class EmptyDataException extends DataException {
  EmptyDataException({
    super.message = 'لا توجد بيانات',
    super.originalException,
    super.stackTrace,
  }) : super(
          code: 'EMPTY_DATA',
        );
}

/// استثناء فشل تحويل البيانات
class DataConversionException extends DataException {
  DataConversionException({
    super.message = 'فشل تحويل البيانات',
    super.originalException,
    super.stackTrace,
  }) : super(
          code: 'DATA_CONVERSION_ERROR',
        );
}

/// استثناء البيانات غير الصحيحة
class InvalidDataException extends DataException {
  InvalidDataException({
    super.message = 'بيانات غير صحيحة',
    super.originalException,
    super.stackTrace,
  }) : super(
          code: 'INVALID_DATA',
        );
}

// ===== Validation Exceptions =====

/// استثناء التحقق العام
class ValidationException extends AppException {
  final List<String> errors;

  ValidationException({
    required super.message,
    required this.errors,
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'VALIDATION_ERROR',
        );
}

// ===== Cache Exceptions =====

/// استثناء الكاش العام
class CacheException extends AppException {
  CacheException({
    super.message = 'خطأ في الكاش',
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'CACHE_ERROR',
        );
}

// ===== Permission Exceptions =====

/// استثناء الصلاحيات
class PermissionException extends AppException {
  PermissionException({
    super.message = 'لا توجد صلاحيات كافية',
    String? code,
    super.originalException,
    super.stackTrace,
  }) : super(
          code: code ?? 'PERMISSION_ERROR',
        );
}

// ===== Unknown Exception =====

/// استثناء غير معروف
class UnknownException extends AppException {
  UnknownException({
    super.message = 'حدث خطأ غير متوقع',
    super.originalException,
    super.stackTrace,
  }) : super(
          code: 'UNKNOWN_ERROR',
        );
}
