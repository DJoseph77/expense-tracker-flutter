import 'package:dio/dio.dart';
import 'package:expense_tracker_flutter/core/network/auth_session_event.dart';
import 'package:expense_tracker_flutter/core/network/jwt_interceptor.dart';
import 'package:expense_tracker_flutter/core/storage/secure_storage_service.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorage implements SecureStorageService {
  String? token = 'mock_jwt_token_xyz';
  UserResponse? user;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String val) async => token = val;

  @override
  Future<void> saveSession(String val, UserResponse u) async {
    token = val;
    user = u;
  }

  @override
  Future<void> deleteToken() async => token = null;

  @override
  Future<bool> containsToken() async => token != null;

  @override
  Future<void> saveUser(UserResponse u) async => user = u;

  @override
  Future<UserResponse?> readUser() async => user;

  @override
  Future<void> deleteUser() async => user = null;

  @override
  Future<void> clearAuthData() async {
    token = null;
    user = null;
  }

  @override
  Future<void> clearSession() async {
    await clearAuthData();
  }
}

class TestRequestInterceptorHandler extends RequestInterceptorHandler {
  RequestOptions? options;
  @override
  void next(RequestOptions requestOptions) {
    options = requestOptions;
  }
}

class TestErrorInterceptorHandler extends ErrorInterceptorHandler {
  DioException? error;
  @override
  void next(DioException err) {
    error = err;
  }
}

void main() {
  group('JwtInterceptor Unit Tests', () {
    late FakeSecureStorage storage;

    setUp(() {
      storage = FakeSecureStorage();
    });

    test('Attaches Authorization header for protected endpoint', () async {
      final interceptor = JwtInterceptor(storage: storage);
      final options = RequestOptions(path: '/api/transactions');
      final handler = TestRequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer mock_jwt_token_xyz');
    });

    test(
      'Does NOT attach Authorization header for /api/auth/login or /api/auth/register',
      () async {
        final interceptor = JwtInterceptor(storage: storage);

        final loginOptions = RequestOptions(path: '/api/auth/login');
        final loginHandler = TestRequestInterceptorHandler();
        await interceptor.onRequest(loginOptions, loginHandler);
        expect(loginOptions.headers['Authorization'], isNull);

        final regOptions = RequestOptions(path: '/api/auth/register');
        final regHandler = TestRequestInterceptorHandler();
        await interceptor.onRequest(regOptions, regHandler);
        expect(regOptions.headers['Authorization'], isNull);
      },
    );

    test(
      'HTTP 401 clears stored JWT and notifies AuthSessionEventService',
      () async {
        final sessionEventService = AuthSessionEventService();
        bool callbackCalled = false;

        sessionEventService.onUnauthorized.listen((msg) {
          callbackCalled = true;
          expect(msg, contains('session expired'));
        });

        final interceptor = JwtInterceptor(
          storage: storage,
          sessionEventService: sessionEventService,
        );

        final err = DioException(
          requestOptions: RequestOptions(path: '/api/transactions'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/transactions'),
            statusCode: 401,
          ),
        );

        final handler = TestErrorInterceptorHandler();
        await interceptor.onError(err, handler);

        expect(storage.token, isNull);
        await pumpEventQueue();
        expect(callbackCalled, isTrue);
      },
    );

    test(
      'HTTP 403 preserves stored JWT and does NOT trigger session event',
      () async {
        final sessionEventService = AuthSessionEventService();
        bool callbackCalled = false;

        sessionEventService.onUnauthorized.listen((msg) {
          callbackCalled = true;
        });

        final interceptor = JwtInterceptor(
          storage: storage,
          sessionEventService: sessionEventService,
        );

        final err = DioException(
          requestOptions: RequestOptions(path: '/api/categories'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/categories'),
            statusCode: 403,
          ),
        );

        final handler = TestErrorInterceptorHandler();
        await interceptor.onError(err, handler);

        expect(storage.token, 'mock_jwt_token_xyz'); // Token preserved
        await pumpEventQueue();
        expect(callbackCalled, isFalse);
        expect(handler.error, equals(err));
      },
    );
  });
}
