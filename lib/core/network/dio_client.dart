import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../storage/secure_storage_service.dart';
import 'jwt_interceptor.dart';

/// Callback handle for 401 unauthorized session expiration
typedef UnauthorizedCallback = void Function(String message);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return createDioClient(
    storage: storage,
    onUnauthorized: (message) {
      ref.read(onUnauthorizedHandlerProvider)?.call(message);
    },
  );
});

final onUnauthorizedHandlerProvider = StateProvider<UnauthorizedCallback?>(
  (ref) => null,
);

Dio createDioClient({
  SecureStorageService? storage,
  UnauthorizedCallback? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  if (storage != null) {
    dio.interceptors.add(
      JwtInterceptor(storage: storage, onUnauthorized: onUnauthorized),
    );
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          final sanitizedPath = options.uri.path;
          debugPrint('HTTP Request: ${options.method} $sanitizedPath');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          final sanitizedPath = response.requestOptions.uri.path;
          debugPrint(
            'HTTP Response [${response.statusCode}]: ${response.requestOptions.method} $sanitizedPath',
          );
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        if (kDebugMode) {
          final sanitizedPath = e.requestOptions.uri.path;
          debugPrint(
            'HTTP Error [${e.response?.statusCode}]: ${e.requestOptions.method} $sanitizedPath (${e.type})',
          );
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
}
