import 'package:flutter/foundation.dart';

/// Debug Logger Utility
/// Centralized logging with different levels and filtering
class DebugLogger {
  static bool _isDebugMode = kDebugMode;
  static LogLevel _minLogLevel = LogLevel.debug;

  /// Enable or disable debug mode
  static void setDebugMode(bool enabled) {
    _isDebugMode = enabled;
  }

  /// Set minimum log level
  static void setMinLogLevel(LogLevel level) {
    _minLogLevel = level;
  }

  /// Log debug message
  static void log(String message, {String? tag, dynamic data}) {
    if (_shouldLog(LogLevel.debug)) {
      _printLog('DEBUG', message, tag: tag, data: data);
    }
  }

  /// Log info message
  static void logInfo(String message, {String? tag, dynamic data}) {
    if (_shouldLog(LogLevel.info)) {
      _printLog('INFO', message, tag: tag, data: data);
    }
  }

  /// Log warning message
  static void logWarning(String message, {String? tag, dynamic data}) {
    if (_shouldLog(LogLevel.warning)) {
      _printLog('WARNING', message, tag: tag, data: data);
    }
  }

  /// Log error message
  static void logError(String message, {String? tag, dynamic data, StackTrace? stackTrace}) {
    if (_shouldLog(LogLevel.error)) {
      _printLog('ERROR', message, tag: tag, data: data, stackTrace: stackTrace);
    }
  }

  /// Log critical error message
  static void logCritical(String message, {String? tag, dynamic data, StackTrace? stackTrace}) {
    if (_shouldLog(LogLevel.critical)) {
      _printLog('CRITICAL', message, tag: tag, data: data, stackTrace: stackTrace);
    }
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration, {String? tag, dynamic data}) {
    if (_shouldLog(LogLevel.info)) {
      _printLog('PERFORMANCE', '$operation took ${duration.inMilliseconds}ms', 
                tag: tag, data: {...?data, 'duration_ms': duration.inMilliseconds});
    }
  }

  /// Log user action
  static void logUserAction(String action, {String? tag, dynamic data}) {
    if (_shouldLog(LogLevel.info)) {
      _printLog('USER_ACTION', action, tag: tag, data: data);
    }
  }

  /// Log network request
  static void logNetwork(String method, String url, {int? statusCode, Duration? duration, String? tag, dynamic data}) {
    if (_shouldLog(LogLevel.info)) {
      final message = '$method $url${statusCode != null ? ' - $statusCode' : ''}';
      final logData = {
        ...?data,
        if (duration != null) 'duration_ms': duration.inMilliseconds,
        if (statusCode != null) 'status_code': statusCode,
      };
      _printLog('NETWORK', message, tag: tag, data: logData);
    }
  }

  /// Log database operation
  static void logDatabase(String operation, String collection, {String? documentId, String? tag, dynamic data}) {
    if (_shouldLog(LogLevel.debug)) {
      final message = '$operation${documentId != null ? ' $documentId' : ''} in $collection';
      _printLog('DATABASE', message, tag: tag, data: data);
    }
  }

  /// Check if should log based on level
  static bool _shouldLog(LogLevel level) {
    return _isDebugMode && level.index >= _minLogLevel.index;
  }

  /// Print log message
  static void _printLog(String level, String message, {String? tag, dynamic data, StackTrace? stackTrace}) {
    final timestamp = DateTime.now().toIso8601String();
    final tagString = tag != null ? '[$tag] ' : '';
    final logMessage = '[$timestamp] $level: $tagString$message';

    if (data != null) {
      debugPrint('$logMessage | Data: $data');
    } else {
      debugPrint(logMessage);
    }

    if (stackTrace != null) {
      debugPrint('Stack Trace:\n$stackTrace');
    }
  }

  /// Create a performance tracker
  static PerformanceTracker startPerformanceTracking(String operation, {String? tag}) {
    return PerformanceTracker(operation, tag: tag);
  }
}

/// Log Level Enum
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Performance Tracker
class PerformanceTracker {
  final String operation;
  final String? tag;
  final Stopwatch _stopwatch;

  PerformanceTracker(this.operation, {this.tag}) : _stopwatch = Stopwatch()..start();

  /// End tracking and log the result
  void end() {
    _stopwatch.stop();
    DebugLogger.logPerformance(operation, _stopwatch.elapsed, tag: tag);
  }

  /// End tracking and return the duration
  Duration get duration {
    _stopwatch.stop();
    return _stopwatch.elapsed;
  }
}

/// Extension for easy performance tracking
extension PerformanceTracking on String {
  PerformanceTracker trackPerformance({String? tag}) {
    return DebugLogger.startPerformanceTracking(this, tag: tag);
  }
}

/// Usage Examples:
/// 
/// // Basic logging
/// DebugLogger.log('User logged in', tag: 'Auth');
/// DebugLogger.logError('Login failed', tag: 'Auth', data: {'email': 'user@example.com'});
/// 
/// // Performance tracking
/// final tracker = DebugLogger.startPerformanceTracking('Database Query');
/// // ... perform operation
/// tracker.end();
/// 
/// // Or using extension
/// 'API Call'.trackPerformance().end();
/// 
/// // Network logging
/// DebugLogger.logNetwork('GET', 'https://api.example.com/users', 
///                       statusCode: 200, duration: const Duration(milliseconds: 500));
/// 
/// // User action logging
/// DebugLogger.logUserAction('Button Clicked', tag: 'UI', data: {'button': 'login'});
