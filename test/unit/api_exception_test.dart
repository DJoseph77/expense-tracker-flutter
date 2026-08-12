import 'package:dio/dio.dart';
import 'package:expense_tracker_flutter/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiException Mapping Tests', () {
    test('Maps timeout exception cleanly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/transactions'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiEx = ApiException.fromDioException(dioException);

      expect(apiEx.type, ApiExceptionType.timeout);
      expect(apiEx.message, contains('timed out'));
    });

    test('Maps HTTP 401 Unauthorized cleanly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/transactions'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/transactions'),
          statusCode: 401,
          data: {'message': 'Bad credentials'},
        ),
      );

      final apiEx = ApiException.fromDioException(dioException);

      expect(apiEx.type, ApiExceptionType.unauthorized);
      expect(apiEx.statusCode, 401);
      expect(apiEx.message, 'Bad credentials');
    });

    test('Maps HTTP 400 Bad Request with custom error message', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/auth/register'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/api/auth/register'),
          statusCode: 400,
          data: {'error': 'Email already in use'},
        ),
      );

      final apiEx = ApiException.fromDioException(dioException);

      expect(apiEx.type, ApiExceptionType.badRequest);
      expect(apiEx.statusCode, 400);
      expect(apiEx.message, 'Email already in use');
    });
  });
}
