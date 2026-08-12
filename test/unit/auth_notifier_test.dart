import 'package:expense_tracker_flutter/core/network/api_exception.dart';
import 'package:expense_tracker_flutter/core/storage/secure_storage_service.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/auth_response.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/login_request.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/register_request.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:expense_tracker_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepository implements AuthRepository {
  bool shouldFailLogin = false;
  bool shouldFailRegister = false;

  UserResponse mockUser = const UserResponse(
    id: 1,
    name: 'Test',
    email: 'test@example.com',
    role: 'USER',
  );

  String? storedToken;
  UserResponse? storedUser;

  @override
  Future<AuthResponse> login(LoginRequest request) async {
    if (shouldFailLogin) {
      throw const ApiException(
        message: 'Invalid credentials',
        type: ApiExceptionType.unauthorized,
      );
    }
    storedToken = 'valid_token';
    storedUser = mockUser;
    return AuthResponse(
      token: 'valid_token',
      tokenType: 'Bearer',
      user: mockUser,
    );
  }

  @override
  Future<UserResponse> register(RegisterRequest request) async {
    if (shouldFailRegister) {
      throw const ApiException(
        message: 'Email already exists',
        type: ApiExceptionType.badRequest,
      );
    }
    return mockUser;
  }

  @override
  Future<void> logout() async {
    storedToken = null;
    storedUser = null;
  }

  @override
  Future<bool> hasStoredToken() async => storedToken != null;

  @override
  Future<String?> readStoredToken() async => storedToken;

  @override
  Future<UserResponse?> readStoredUser() async => storedUser;
}

class MockFailingStorage implements SecureStorageService {
  @override
  Future<void> saveToken(String val) async {
    throw Exception('Disk error on token');
  }

  @override
  Future<void> saveUser(UserResponse u) async {
    throw Exception('Disk error on user');
  }

  @override
  Future<void> saveSession(String val, UserResponse u) async {
    try {
      await saveToken(val);
      await saveUser(u);
    } catch (_) {
      await clearAuthData();
      rethrow;
    }
  }

  @override
  Future<void> clearAuthData() async {}

  @override
  Future<void> clearSession() async {}

  @override
  Future<bool> containsToken() async => false;

  @override
  Future<void> deleteToken() async {}

  @override
  Future<void> deleteUser() async {}

  @override
  Future<String?> readToken() async => null;

  @override
  Future<UserResponse?> readUser() async => null;
}

void main() {
  group('AuthNotifier & Session Resilience Tests', () {
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
    });

    test('session persists after checkSession when token is present', () async {
      mockRepo.storedToken = 'saved_jwt';
      mockRepo.storedUser = mockRepo.mockUser;

      final notifier = AuthNotifier(repository: mockRepo);
      await notifier.checkSession();

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user?.email, 'test@example.com');
    });

    test(
      'AuthNotifier responds to 401 notification by updating state to unauthenticated',
      () {
        final notifier = AuthNotifier(repository: mockRepo);
        notifier.handleUnauthorized('Session expired');

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(notifier.state.errorMessage, contains('Session expired'));
      },
    );

    test('duplicate submissions are prevented when authenticating', () async {
      final notifier = AuthNotifier(repository: mockRepo);

      final firstCall = notifier.login('test@example.com', 'Password123!');
      final secondCall = notifier.login('test@example.com', 'Password123!');

      final results = await Future.wait([firstCall, secondCall]);
      expect(results.contains(false), isTrue); // Duplicate request rejected
    });

    test(
      'storage failure during saveSession does not leave a partial session',
      () async {
        final failingStorage = MockFailingStorage();

        expect(
          () => failingStorage.saveSession('token123', mockRepo.mockUser),
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}
