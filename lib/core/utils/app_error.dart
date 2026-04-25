import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

/// Base App Error Class
abstract class AppError extends Equatable {
  final String message;
  final String? code;
  final dynamic details;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.code,
    this.details,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, code, details];

  @override
  String toString() => 'AppError: $message';
}

/// Network Error
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code = 'NETWORK_ERROR',
    super.details,
    super.stackTrace,
  });

  factory NetworkError.timeout({StackTrace? stackTrace}) {
    return NetworkError(
      message: 'Connection timeout. Please check your internet connection.',
      code: 'TIMEOUT',
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.noInternet({StackTrace? stackTrace}) {
    return NetworkError(
      message: 'No internet connection. Please check your network settings.',
      code: 'NO_INTERNET',
      stackTrace: stackTrace,
    );
  }

  factory NetworkError.serverError({String? message, StackTrace? stackTrace}) {
    return NetworkError(
      message: message ?? 'Server error. Please try again later.',
      code: 'SERVER_ERROR',
      stackTrace: stackTrace,
    );
  }
}

/// Authentication Error
class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code,
    super.details,
    super.stackTrace,
  });

  factory AuthError.invalidCredentials({StackTrace? stackTrace}) {
    return AuthError(
      message: 'Invalid email or password.',
      code: 'INVALID_CREDENTIALS',
      stackTrace: stackTrace,
    );
  }

  factory AuthError.sessionExpired({StackTrace? stackTrace}) {
    return AuthError(
      message: 'Your session has expired. Please login again.',
      code: 'SESSION_EXPIRED',
      stackTrace: stackTrace,
    );
  }

  factory AuthError.userNotFound({StackTrace? stackTrace}) {
    return AuthError(
      message: 'User not found. Please check your credentials.',
      code: 'USER_NOT_FOUND',
      stackTrace: stackTrace,
    );
  }

  factory AuthError.accountDisabled({StackTrace? stackTrace}) {
    return AuthError(
      message: 'Your account has been disabled. Please contact support.',
      code: 'ACCOUNT_DISABLED',
      stackTrace: stackTrace,
    );
  }
}

/// Validation Error
class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
    super.details,
    super.stackTrace,
  });

  factory ValidationError.emailInvalid({StackTrace? stackTrace}) {
    return ValidationError(
      message: 'Please enter a valid email address.',
      code: 'EMAIL_INVALID',
      stackTrace: stackTrace,
    );
  }

  factory ValidationError.passwordWeak({StackTrace? stackTrace}) {
    return ValidationError(
      message: 'Password must be at least 8 characters long.',
      code: 'PASSWORD_WEAK',
      stackTrace: stackTrace,
    );
  }

  factory ValidationError.fieldRequired(String fieldName, {StackTrace? stackTrace}) {
    return ValidationError(
      message: '$fieldName is required.',
      code: 'FIELD_REQUIRED',
      details: {'field': fieldName},
      stackTrace: stackTrace,
    );
  }
}

/// Database Error
class DatabaseError extends AppError {
  const DatabaseError({
    required super.message,
    super.code,
    super.details,
    super.stackTrace,
  });

  factory DatabaseError.documentNotFound({String? documentId, StackTrace? stackTrace}) {
    return DatabaseError(
      message: 'Document not found${documentId != null ? ': $documentId' : ''}.',
      code: 'DOCUMENT_NOT_FOUND',
      details: {'documentId': documentId},
      stackTrace: stackTrace,
    );
  }

  factory DatabaseError.permissionDenied({StackTrace? stackTrace}) {
    return DatabaseError(
      message: 'You don\'t have permission to access this resource.',
      code: 'PERMISSION_DENIED',
      stackTrace: stackTrace,
    );
  }

  factory DatabaseError.connectionFailed({StackTrace? stackTrace}) {
    return DatabaseError(
      message: 'Database connection failed. Please try again.',
      code: 'CONNECTION_FAILED',
      stackTrace: stackTrace,
    );
  }
}

/// File/Storage Error
class StorageError extends AppError {
  const StorageError({
    required super.message,
    super.code,
    super.details,
    super.stackTrace,
  });

  factory StorageError.fileTooBig({int? maxSize, StackTrace? stackTrace}) {
    return StorageError(
      message: 'File is too big${maxSize != null ? '. Maximum size: ${maxSize}MB' : ''}.',
      code: 'FILE_TOO_BIG',
      details: {'maxSize': maxSize},
      stackTrace: stackTrace,
    );
  }

  factory StorageError.invalidFileType({StackTrace? stackTrace}) {
    return StorageError(
      message: 'Invalid file type. Please upload a valid file.',
      code: 'INVALID_FILE_TYPE',
      stackTrace: stackTrace,
    );
  }

  factory StorageError.uploadFailed({StackTrace? stackTrace}) {
    return StorageError(
      message: 'File upload failed. Please try again.',
      code: 'UPLOAD_FAILED',
      stackTrace: stackTrace,
    );
  }
}

/// System Error
class SystemError extends AppError {
  const SystemError({
    required super.message,
    super.code,
    super.details,
    super.stackTrace,
  });
}

/// Unknown Error
class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.code,
    super.details,
    super.stackTrace,
  });

  factory UnknownError.fromException(Exception exception, {StackTrace? stackTrace}) {
    return UnknownError(
      message: 'An unexpected error occurred: ${exception.toString()}',
      code: 'UNKNOWN_ERROR',
      details: {'exception': exception.toString()},
      stackTrace: stackTrace,
    );
  }
}

/// Error Handler Utility
class ErrorHandler {
  static AppError handleError(dynamic error, {StackTrace? stackTrace}) {
    if (error is AppError) {
      return error;
    }

    // Network errors
    if (error.toString().contains('timeout') || error.toString().contains('connection')) {
      return NetworkError.timeout(stackTrace: stackTrace);
    }

    // Firebase Auth errors
    if (error.toString().contains('user-not-found')) {
      return AuthError.userNotFound(stackTrace: stackTrace);
    }

    if (error.toString().contains('invalid-credential')) {
      return AuthError.invalidCredentials(stackTrace: stackTrace);
    }

    if (error.toString().contains('session-expired')) {
      return AuthError.sessionExpired(stackTrace: stackTrace);
    }

    // Default to unknown error
    return UnknownError.fromException(
      error is Exception ? error : Exception(error.toString()),
      stackTrace: stackTrace,
    );
  }

  static String getErrorMessage(AppError error) {
    return error.message;
  }

  static String getErrorCode(AppError error) {
    return error.code ?? 'UNKNOWN';
  }

  static bool isNetworkError(AppError error) {
    return error is NetworkError;
  }

  static bool isAuthError(AppError error) {
    return error is AuthError;
  }

  static bool isValidationError(AppError error) {
    return error is ValidationError;
  }

  static bool isDatabaseError(AppError error) {
    return error is DatabaseError;
  }

  static bool isStorageError(AppError error) {
    return error is StorageError;
  }

  static void logError(AppError error) {
    debugPrint('Error: ${error.toString()}');
    debugPrint('Code: ${error.code}');
    debugPrint('Details: ${error.details}');
    if (error.stackTrace != null) {
      debugPrint('Stack Trace: ${error.stackTrace}');
    }
  }
}
