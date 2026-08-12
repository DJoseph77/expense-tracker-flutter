import 'package:dio/dio.dart';
import 'package:expense_tracker_flutter/core/network/api_endpoints.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker_flutter/features/dashboard/presentation/screens/home_screen.dart';
import 'package:expense_tracker_flutter/features/statistics/data/models/statistics_response.dart';
import 'package:expense_tracker_flutter/features/statistics/data/repositories/statistics_repository.dart';
import 'package:expense_tracker_flutter/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

class FakeStatisticsRepository implements StatisticsRepository {
  StatisticsResponse mockSummary = const StatisticsResponse(
    income: '3500.00',
    expenses: '1200.50',
    balance: '2299.50',
  );

  bool shouldFail = false;
  int getSummaryCallCount = 0;

  @override
  Future<StatisticsResponse> getSummary() async {
    getSummaryCallCount++;
    if (shouldFail) {
      throw Exception('Server error loading summary');
    }
    return mockSummary;
  }
}

class FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  FakeAuthNotifier(super.state);
  @override
  Future<void> checkSession() async {}
  @override
  void handleUnauthorized(String message) {}
  @override
  Future<bool> login(String email, String password) async => true;
  @override
  Future<void> logout() async {}
  @override
  Future<UserResponse?> register(
    String name,
    String email,
    String password,
  ) async => null;
}

void main() {
  group('StatisticsRepository Unit Tests', () {
    late Dio dio;

    setUp(() {
      dio = Dio(
        BaseOptions(baseUrl: 'https://expense-tracker-api-x8nw.onrender.com'),
      );
    });

    test('getSummary parses numeric and floating point JSON values', () async {
      dio.httpClientAdapter = FakeDioAdapter()
        ..onRequest = (options) {
          expect(options.path, ApiEndpoints.statisticsSummary);
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: '''
            {
              "income": 3500,
              "expenses": 1200.5,
              "balance": 2299.5
            }
            ''',
          );
        };

      final repo = StatisticsRepository(dio: dio);
      final summary = await repo.getSummary();

      expect(summary.income, '3500.00');
      expect(summary.expenses, '1200.50');
      expect(summary.balance, '2299.50');
    });

    test('getSummary parses string monetary JSON values', () async {
      dio.httpClientAdapter = FakeDioAdapter()
        ..onRequest = (options) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: '''
            {
              "income": "5000.00",
              "expenses": "2000.00",
              "balance": "3000.00"
            }
            ''',
          );
        };

      final repo = StatisticsRepository(dio: dio);
      final summary = await repo.getSummary();

      expect(summary.income, '5000.00');
      expect(summary.expenses, '2000.00');
      expect(summary.balance, '3000.00');
    });

    test('getSummary parses zero summary correctly', () async {
      dio.httpClientAdapter = FakeDioAdapter()
        ..onRequest = (options) {
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: '''
            {
              "income": 0,
              "expenses": 0,
              "balance": 0
            }
            ''',
          );
        };

      final repo = StatisticsRepository(dio: dio);
      final summary = await repo.getSummary();

      expect(summary.income, '0.00');
      expect(summary.expenses, '0.00');
      expect(summary.balance, '0.00');
    });
  });

  group('StatisticsNotifier Unit Tests', () {
    late FakeStatisticsRepository repository;

    setUp(() {
      repository = FakeStatisticsRepository();
    });

    test('Initial load populates summary state', () async {
      final notifier = StatisticsNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      final state = notifier.state;
      expect(state.summary, isNotNull);
      expect(state.summary!.income, '3500.00');
      expect(state.isInitialLoading, isFalse);
    });

    test('Refresh updates summary while preserving state on failure', () async {
      final notifier = StatisticsNotifier(repository: repository);
      await Future.delayed(Duration.zero);

      // Successful refresh
      repository.mockSummary = const StatisticsResponse(
        income: '4000.00',
        expenses: '1500.00',
        balance: '2500.00',
      );
      await notifier.refresh();
      expect(notifier.state.summary!.income, '4000.00');

      // Failed refresh preserves existing summary
      repository.shouldFail = true;
      await notifier.refresh();
      expect(notifier.state.summary!.income, '4000.00');
      expect(notifier.state.errorMessage, isNotNull);
    });
  });

  group('Statistics Dashboard Widget Tests', () {
    testWidgets('Renders statistics cards with balance, income, and expenses', (
      tester,
    ) async {
      final authState = const AuthState(
        status: AuthStatus.authenticated,
        user: UserResponse(
          id: 1,
          name: 'Dashboard User',
          email: 'user@example.com',
          role: 'USER',
        ),
      );

      final repo = FakeStatisticsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(authState),
            ),
            statisticsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('\$2299.50'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('\$3500.00'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('\$1200.50'), findsOneWidget);
    });

    testWidgets('Renders negative balance correctly', (tester) async {
      final authState = const AuthState(
        status: AuthStatus.authenticated,
        user: UserResponse(
          id: 1,
          name: 'User',
          email: 'user@example.com',
          role: 'USER',
        ),
      );

      final repo = FakeStatisticsRepository();
      repo.mockSummary = const StatisticsResponse(
        income: '100.00',
        expenses: '500.00',
        balance: '-400.00',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(authState),
            ),
            statisticsRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('-\$400.00'), findsOneWidget);
    });

    testWidgets('USER role cannot see Manage Categories button on Dashboard', (
      tester,
    ) async {
      final authState = const AuthState(
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
              (ref) => FakeAuthNotifier(authState),
            ),
            statisticsRepositoryProvider.overrideWithValue(
              FakeStatisticsRepository(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manage Categories'), findsNothing);
    });

    testWidgets('ADMIN role CAN see Manage Categories button on Dashboard', (
      tester,
    ) async {
      final authState = const AuthState(
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
              (ref) => FakeAuthNotifier(authState),
            ),
            statisticsRepositoryProvider.overrideWithValue(
              FakeStatisticsRepository(),
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manage Categories'), findsOneWidget);
    });

    testWidgets(
      'Dashboard layout on narrow screen (300px width) renders without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final authState = const AuthState(
          status: AuthStatus.authenticated,
          user: UserResponse(
            id: 1,
            name: 'Narrow Screen User',
            email: 'user@example.com',
            role: 'ADMIN',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => FakeAuthNotifier(authState),
              ),
              statisticsRepositoryProvider.overrideWithValue(
                FakeStatisticsRepository(),
              ),
            ],
            child: const MaterialApp(home: HomeScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
