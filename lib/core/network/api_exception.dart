import 'package:dio/dio.dart';

enum ApiExceptionType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  timeout,
  networkError,
  unknown,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;

  const ApiException({
    required this.message,
    this.statusCode,
    required this.type,
  });

  factory ApiException.fromDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ApiException(
        message: 'Server connection timed out. The server may be waking up.',
        type: ApiExceptionType.timeout,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return const ApiException(
        message:
            'Unable to connect to the network. Please check your connection.',
        type: ApiExceptionType.networkError,
      );
    }

    final statusCode = e.response?.statusCode;
    final extractedMsg = _extractSafeErrorMessage(e.response?.data);

    if (statusCode == 400) {
      return ApiException(
        message: extractedMsg ?? 'Invalid request details provided.',
        statusCode: statusCode,
        type: ApiExceptionType.badRequest,
      );
    }

    if (statusCode == 401) {
      return ApiException(
        message: extractedMsg ?? 'Authentication failed. Please log in again.',
        statusCode: statusCode,
        type: ApiExceptionType.unauthorized,
      );
    }

    if (statusCode == 403) {
      return ApiException(
        message: extractedMsg ?? 'Access denied. You do not have permission.',
        statusCode: statusCode,
        type: ApiExceptionType.forbidden,
      );
    }

    if (statusCode == 404) {
      return ApiException(
        message: extractedMsg ?? 'Requested resource was not found.',
        statusCode: statusCode,
        type: ApiExceptionType.notFound,
      );
    }

    if (statusCode == 409) {
      return ApiException(
        message: extractedMsg ?? 'Resource conflict occurred.',
        statusCode: statusCode,
        type: ApiExceptionType.conflict,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        message: 'Server error encountered. Please try again later.',
        statusCode: statusCode,
        type: ApiExceptionType.serverError,
      );
    }

    return ApiException(
      message: extractedMsg ?? 'An unexpected network error occurred.',
      statusCode: statusCode,
      type: ApiExceptionType.unknown,
    );
  }

  static String? _extractSafeErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final msg = data['message'] ?? data['error'] ?? data['detail'];
      if (msg is String && msg.trim().isNotEmpty) {
        return msg.trim();
      }
    }
    return null;
  }

  @override
  String toString() => 'ApiException [$type, code=$statusCode]: $message';
}
