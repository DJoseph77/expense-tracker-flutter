import 'package:expense_tracker_flutter/core/storage/secure_storage_service.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorage implements SecureStorageService {
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
  @override
  Future<void> saveSession(String token, UserResponse user) async {}
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> saveUser(UserResponse user) async {}
}

void main() {
  group('ProviderScope Startup & Clean Initialization Tests', () {
    testWidgets(
      'AuthNotifier initializes inside ProviderScope without throwing Riverpod errors',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              secureStorageProvider.overrideWithValue(FakeSecureStorage()),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);
                return MaterialApp(
                  home: Scaffold(body: Text('Status: ${authState.status}')),
                );
              },
            ),
          ),
        );

        // Verify that initialization completes without throw
        expect(find.byType(MaterialApp), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.textContaining('Status:'), findsOneWidget);
      },
    );
  });
}
