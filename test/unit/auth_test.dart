import 'package:dio/dio.dart';
import 'package:expense_tracker_flutter/core/network/api_endpoints.dart';
import 'package:expense_tracker_flutter/core/network/api_exception.dart';
import 'package:expense_tracker_flutter/core/storage/secure_storage_service.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/login_request.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/register_request.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorageService implements SecureStorageService {
  String? token;
  UserResponse? user;

  @override
  Future<void> saveToken(String val) async {
    token = val;
  }

  @override
  Future<void> saveSession(String val, UserResponse u) async {
    token = val;
    user = u;
  }

  @override
  Future<String?> readToken() async {
    return token;
  }

  @override
  Future<void> deleteToken() async {
    token = null;
  }

  @override
  Future<bool> containsToken() async {
    return token != null;
  }

  @override
  Future<void> saveUser(UserResponse u) async {
    user = u;
  }

  @override
  Future<UserResponse?> readUser() async => user;

  @override
  Future<void> deleteUser() async {
    user = null;
  }

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

class FakeDioAdapter implements HttpClientAdapter {
  late Response Function(RequestOptions options) onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = onRequest(options);
    return ResponseBody.fromString(
      response.data.toString(),
      response.statusCode ?? 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AuthRepository Unit Tests', () {
    late FakeSecureStorageService fakeStorage;
    late Dio dio;

    setUp(() {
      fakeStorage = FakeSecureStorageService();
      dio = Dio(
        BaseOptions(baseUrl: 'https://expense-tracker-api-x8nw.onrender.com'),
      );
    });

    test('login success (200 OK) stores token and user profile', () async {
      dio.httpClientAdapter = FakeDioAdapter()
        ..onRequest = (options) {
          expect(options.path, ApiEndpoints.authLogin);
          expect(options.data['email'], 'test@example.com');
          return Response(
            requestOptions: options,
            statusCode: 200,
            data:
                '{"token":"test_jwt_123","tokenType":"Bearer","user":{"id":1,"name":"Test","email":"test@example.com","role":"USER"}}',
          );
        };

      final repo = AuthRepository(dio: dio, storage: fakeStorage);
      final authResp = await repo.login(
        const LoginRequest(email: 'test@example.com', password: 'Password123!'),
      );

      expect(authResp.token, 'test_jwt_123');
      expect(fakeStorage.token, 'test_jwt_123');
      expect(fakeStorage.user?.email, 'test@example.com');
    });

    test('failed login does not store a token', () async {
      dio.httpClientAdapter = FakeDioAdapter()
        ..onRequest = (options) {
          return Response(
            requestOptions: options,
            statusCode: 401,
            data: '{"message":"Bad credentials"}',
          );
        };

      final repo = AuthRepository(dio: dio, storage: fakeStorage);

      expect(
        () => repo.login(
          const LoginRequest(email: 'bad@example.com', password: 'wrong'),
        ),
        throwsA(isA<ApiException>()),
      );

      expect(fakeStorage.token, isNull);
    });

    test(
      'registration expects HTTP 201 UserResponse and does NOT store a JWT',
      () async {
        dio.httpClientAdapter = FakeDioAdapter()
          ..onRequest = (options) {
            expect(options.path, ApiEndpoints.authRegister);
            return Response(
              requestOptions: options,
              statusCode: 201,
              data:
                  '{"id":10,"name":"New User","email":"new@example.com","role":"USER"}',
            );
          };

        final repo = AuthRepository(dio: dio, storage: fakeStorage);
        final user = await repo.register(
          const RegisterRequest(
            name: 'New User',
            email: 'new@example.com',
            password: 'Password123!',
          ),
        );

        expect(user.id, 10);
        expect(user.email, 'new@example.com');
        expect(fakeStorage.token, isNull); // No JWT saved on registration
      },
    );

    test('logout clears stored JWT token and profile', () async {
      fakeStorage.token = 'existing_jwt';
      final repo = AuthRepository(dio: dio, storage: fakeStorage);

      await repo.logout();

      expect(fakeStorage.token, isNull);
      expect(fakeStorage.user, isNull);
    });
  });
}
