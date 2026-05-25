import 'package:dio/dio.dart';
import 'package:gomhor_alahly_clean_new/core/exceptions/app_exceptions.dart';
import 'package:gomhor_alahly_clean_new/core/utils/error_handler.dart';

class ApiClient {
  ApiClient({
    required Dio dio,
    Map<String, String>? defaultHeaders,
  })  : _dio = dio,
        _defaultHeaders = defaultHeaders ?? const <String, String>{};

  final Dio _dio;
  final Map<String, String> _defaultHeaders;

  Map<String, dynamic> _mergeHeaders(Map<String, dynamic>? headers) {
    final merged = <String, dynamic>{..._defaultHeaders, ...?headers};
    return merged;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: Options(headers: _mergeHeaders(headers)),
        cancelToken: cancelToken,
      );
    } catch (e, st) {
      throw ErrorHandler.handleError(e, st);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: _mergeHeaders(headers)),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
    } catch (e, st) {
      throw ErrorHandler.handleError(e, st);
    }
  }

  Future<T> getJson<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    final res = await get<dynamic>(
      path,
      queryParameters: queryParameters,
      headers: headers,
      cancelToken: cancelToken,
    );
    final data = res.data;
    if (data is T) return data;
    throw InvalidDataException(
      message: 'استجابة غير متوقعة من الخادم',
      originalException: data,
    );
  }
}

