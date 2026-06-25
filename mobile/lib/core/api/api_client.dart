import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Singleton Dio HTTP client pre-configured for the OSINT backend.
///
/// - Reads [baseUrl] from the environment (set at build time via --dart-define).
/// - Attaches `Authorization: Bearer <token>` when a token is stored.
/// - Wraps Dio errors into [ApiException] for clean error handling.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 90), // OSINT jobs take time
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      LogInterceptor(requestBody: true, responseBody: false),
    ]);
  }

  static final ApiClient instance = ApiClient._();

  /// Override this for testing or custom deployments.
  static String _baseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

  static void setBaseUrl(String url) {
    _baseUrl = url;
    instance._dio.options.baseUrl = url;
  }

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get dio => _dio;

  // ── Convenience wrappers ──────────────────────────────────────────────────

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    try {
      return await _dio.post<T>(path, data: data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response<T>> delete<T>(String path) async {
    try {
      return await _dio.delete<T>(path);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    if (e.response != null) {
      final msg = e.response?.data?['error'] ??
          e.response?.data?['detail'] ??
          'Server error ${e.response?.statusCode}';
      return ApiException(msg.toString(), statusCode: e.response?.statusCode);
    }
    return ApiException(
      e.type == DioExceptionType.connectionTimeout
          ? 'Connection timed out. Is the server running?'
          : 'Network error: ${e.message}',
    );
  }
}

// ── Auth interceptor ──────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  const _AuthInterceptor(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ── ApiException ──────────────────────────────────────────────────────────────

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
