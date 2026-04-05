import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Network Utilities
class NetworkUtils {
  static final NetworkUtils _instance = NetworkUtils._internal();

  factory NetworkUtils() {
    return _instance;
  }

  NetworkUtils._internal();

  final Connectivity _connectivity = Connectivity();
  late Dio _dio;

  /// Initialize Network Utils
  void initialize() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    // Add Interceptors
    _dio.interceptors.add(LoggingInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
  }

  /// Check Internet Connection
  Future<bool> hasInternetConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Get Connection Type
  Future<ConnectivityResult> getConnectionType() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      return ConnectivityResult.none;
    }
  }

  /// Stream Connection Changes
  Stream<ConnectivityResult> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged;
  }

  /// GET Request
  Future<dynamic> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// POST Request
  Future<dynamic> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// PUT Request
  Future<dynamic> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE Request
  Future<dynamic> delete(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH Request
  Future<dynamic> patch(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload File
  Future<dynamic> uploadFile(
    String url,
    String filePath, {
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        ...?additionalFields,
      });

      final response = await _dio.post(
        url,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Download File
  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Logging Interceptor
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('REQUEST[\${options.method}] => PATH: \${options.path}');
    debugPrint('Headers: \${options.headers}');
    debugPrint('Body: \${options.data}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
        'RESPONSE[\${response.statusCode}] => PATH: \${response.requestOptions.path}');
    debugPrint('Data: \${response.data}');
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
        'ERROR[\${err.response?.statusCode}] => PATH: \${err.requestOptions.path}');
    debugPrint('Message: \${err.message}');
    return super.onError(err, handler);
  }
}

/// Error Interceptor
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle specific error codes
    if (err.response?.statusCode == 401) {
      // Unauthorized - Handle logout
      debugPrint('Unauthorized - Logout user');
    } else if (err.response?.statusCode == 403) {
      // Forbidden
      debugPrint('Forbidden');
    } else if (err.response?.statusCode == 404) {
      // Not Found
      debugPrint('Not Found');
    } else if (err.response?.statusCode == 500) {
      // Server Error
      debugPrint('Server Error');
    }

    return super.onError(err, handler);
  }
}

/// Network State
enum NetworkState {
  connected,
  disconnected,
  mobile,
  wifi,
  unknown,
}

/// Network Status Listener
typedef NetworkStatusListener = void Function(NetworkState state);

/// Network Status Manager
class NetworkStatusManager {
  static final NetworkStatusManager _instance =
      NetworkStatusManager._internal();

  factory NetworkStatusManager() {
    return _instance;
  }

  NetworkStatusManager._internal();

  final List<NetworkStatusListener> _listeners = [];
  NetworkState _currentState = NetworkState.unknown;

  NetworkState get currentState => _currentState;

  /// Initialize
  void initialize() {
    NetworkUtils().onConnectivityChanged().listen((result) {
      _updateState(result);
    });
  }

  /// Add Listener
  void addListener(NetworkStatusListener listener) {
    _listeners.add(listener);
  }

  /// Remove Listener
  void removeListener(NetworkStatusListener listener) {
    _listeners.remove(listener);
  }

  /// Notify Listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_currentState);
    }
  }

  /// Update State
  void _updateState(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.mobile:
        _currentState = NetworkState.mobile;
        break;
      case ConnectivityResult.wifi:
        _currentState = NetworkState.wifi;
        break;
      case ConnectivityResult.none:
        _currentState = NetworkState.disconnected;
        break;
      default:
        _currentState = NetworkState.unknown;
    }
    _notifyListeners();
  }
}
