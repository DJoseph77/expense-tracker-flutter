import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';

class JwtInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final void Function(String message)? _onUnauthorized;

  JwtInterceptor({
    required SecureStorageService storage,
    void Function(String message)? onUnauthorized,
  }) : _storage = storage,
       _onUnauthorized = onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;

    // Do not attach token for public auth endpoints
    if (path == ApiEndpoints.authLogin || path == ApiEndpoints.authRegister) {
      return handler.next(options);
    }

    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      await _storage.clearAuthData();
      _onUnauthorized?.call('Your session expired. Please log in again.');
    }

    return handler.next(err);
  }
}
