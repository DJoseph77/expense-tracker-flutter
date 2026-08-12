import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/models/user_response.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_jwt_token';
  static const String _userKey = 'auth_user_profile';

  const SecureStorageService(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> containsToken() async {
    return await _storage.containsKey(key: _tokenKey);
  }

  Future<void> saveUser(UserResponse user) async {
    final jsonStr = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: jsonStr);
  }

  Future<UserResponse?> readUser() async {
    final jsonStr = await _storage.read(key: _userKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserResponse.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
  }

  Future<void> clearAuthData() async {
    await deleteToken();
    await deleteUser();
  }
}
