import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_response.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio: dio, storage: storage);
});

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository({required Dio dio, required SecureStorageService storage})
    : _dio = dio,
      _storage = storage;

  /// Registration endpoint POST /api/auth/register
  /// Expects HTTP 201 Created. Returns UserResponse.
  /// Does NOT authenticate or store a token.
  Future<UserResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authRegister,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserResponse.fromJson(response.data as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Registration failed. Unexpected server response.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Login endpoint POST /api/auth/login
  /// Expects HTTP 200 OK. Returns AuthResponse.
  /// Saves token and user profile to SecureStorage.
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.authLogin,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        // Store JWT token and user profile safely (atomic session save with rollback)
        await _storage.saveSession(authResponse.token, authResponse.user);

        return authResponse;
      }

      throw const ApiException(
        message: 'Login failed. Invalid credentials.',
        type: ApiExceptionType.unauthorized,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Logs out by deleting stored token and user profile
  Future<void> logout() async {
    await _storage.clearAuthData();
  }

  Future<String?> readStoredToken() async {
    return await _storage.readToken();
  }

  Future<bool> hasStoredToken() async {
    return await _storage.containsToken();
  }

  Future<UserResponse?> readStoredUser() async {
    return await _storage.readUser();
  }
}
