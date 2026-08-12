import 'package:dio/dio.dart';
import 'package:expense_tracker_flutter/core/network/api_exception.dart';
import 'package:expense_tracker_flutter/core/network/auth_session_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7 Security & Resilience Tests', () {
    test(
      'ApiException maps Dio connection timeout to user-friendly server waking message',
      () {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
        );

        final apiException = ApiException.fromDioException(dioException);
        expect(apiException.message, contains('server may be waking up'));
      },
    );

    test(
      'ApiException maps Dio sendTimeout to user-friendly server waking message',
      () {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/api/test'),
          type: DioExceptionType.sendTimeout,
          message: 'Send timed out',
        );

        final apiException = ApiException.fromDioException(dioException);
        expect(apiException.message, contains('server may be waking up'));
      },
    );

    test(
      'AuthSessionEventService broadcasts 401 unauthorized session event',
      () async {
        final sessionService = AuthSessionEventService();
        bool eventReceived = false;

        final sub = sessionService.onUnauthorized.listen((msg) {
          eventReceived = true;
          expect(msg, 'Session expired');
        });

        sessionService.notifyUnauthorized('Session expired');
        await Future.delayed(Duration.zero);

        expect(eventReceived, isTrue);
        await sub.cancel();
      },
    );

    test(
      'HTTP 403 Forbidden ApiException maps correctly without logging out',
      () {
        final dioException = DioException(
          requestOptions: RequestOptions(path: '/api/categories'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/categories'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        );

        final apiException = ApiException.fromDioException(dioException);
        expect(apiException.type, ApiExceptionType.forbidden);
        expect(apiException.message, contains('permission'));
      },
    );
  });
}
