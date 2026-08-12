import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';

final dioProvider = Provider<Dio>((ref) {
  return createDioClient();
});

Dio createDioClient() {
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
