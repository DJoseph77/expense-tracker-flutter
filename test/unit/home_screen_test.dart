import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker_flutter/features/dashboard/presentation/screens/home_screen.dart';
import 'package:expense_tracker_flutter/features/statistics/data/models/statistics_response.dart';
import 'package:expense_tracker_flutter/features/statistics/data/repositories/statistics_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  bool logoutCalled = false;

  FakeAuthNotifier(super.state);

  @override
  Future<void> checkSession() async {}

  @override
  void handleUnauthorized(String message) {}

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  @override
  Future<UserResponse?> register(
    String name,
    String email,
    String password,
  ) async => null;
}

class FakeStatisticsRepository implements StatisticsRepository {
  @override
  Future<StatisticsResponse> getSummary() async {
    return const StatisticsResponse(
      income: '3500.00',
      expenses: '1200.50',
      balance: '2299.50',
    );
  }
}

void main() {
  group('HomeScreen UI & Role-Based Action Tests', () {
    testWidgets('USER role does NOT see Manage Categories button', (
      tester,
    ) async {
      final userState = const AuthState(
        status: AuthStatus.authenticated,
        user: UserResponse(
          id: 1,
          name: 'Normal User',
          email: 'user@example.com',
          role: 'USER',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(userState),
            ),
            statisticsRepositoryProvider.overrideWithValue(
              FakeStatisticsRepository(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('View Transactions'), findsOneWidget);
      expect(find.text('Manage Categories'), findsNothing);
    });

    testWidgets('ADMIN role DOES see Manage Categories button', (tester) async {
      final adminState = const AuthState(
        status: AuthStatus.authenticated,
        user: UserResponse(
          id: 2,
          name: 'Admin User',
          email: 'admin@example.com',
          role: 'ADMIN',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(adminState),
            ),
            statisticsRepositoryProvider.overrideWithValue(
              FakeStatisticsRepository(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('View Transactions'), findsOneWidget);
      expect(find.text('Manage Categories'), findsOneWidget);
    });

    testWidgets('HomeScreen body does NOT contain a second Sign Out button', (
      tester,
    ) async {
      final userState = const AuthState(
        status: AuthStatus.authenticated,
        user: UserResponse(
          id: 1,
          name: 'User',
          email: 'user@example.com',
          role: 'USER',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(userState),
            ),
            statisticsRepositoryProvider.overrideWithValue(
              FakeStatisticsRepository(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsNothing);
    });

    testWidgets('AppBar logout action exists and invokes logout()', (
      tester,
    ) async {
      final userState = const AuthState(
        status: AuthStatus.authenticated,
        user: UserResponse(
          id: 1,
          name: 'User',
          email: 'user@example.com',
          role: 'USER',
        ),
      );

      final fakeNotifier = FakeAuthNotifier(userState);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => fakeNotifier),
            statisticsRepositoryProvider.overrideWithValue(
              FakeStatisticsRepository(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      final logoutIconButton = find.byIcon(Icons.logout);
      expect(logoutIconButton, findsOneWidget);

      await tester.tap(logoutIconButton);
      await tester.pumpAndSettle();

      expect(fakeNotifier.logoutCalled, isTrue);
    });
  });
}
