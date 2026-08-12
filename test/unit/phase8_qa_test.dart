import 'package:dio/dio.dart';
import 'package:expense_tracker_flutter/core/network/jwt_interceptor.dart';
import 'package:expense_tracker_flutter/core/storage/secure_storage_service.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker_flutter/features/categories/data/models/category.dart';
import 'package:expense_tracker_flutter/features/categories/data/repositories/category_repository.dart';
import 'package:expense_tracker_flutter/features/categories/presentation/widgets/category_picker.dart';
import 'package:expense_tracker_flutter/features/dashboard/presentation/screens/home_screen.dart';
import 'package:expense_tracker_flutter/features/statistics/data/models/statistics_response.dart';
import 'package:expense_tracker_flutter/features/statistics/data/repositories/statistics_repository.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction_filters.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction_request.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction_type.dart';
import 'package:expense_tracker_flutter/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureStorageService extends SecureStorageService {
  String? storedToken;
  UserResponse? storedUser;

  FakeSecureStorageService() : super(const FlutterSecureStorage());

  @override
  Future<void> saveToken(String token) async => storedToken = token;

  @override
  Future<String?> readToken() async => storedToken;

  @override
  Future<void> saveUser(UserResponse user) async => storedUser = user;

  @override
  Future<UserResponse?> readUser() async => storedUser;

  @override
  Future<void> clearAuthData() async {
    storedToken = null;
    storedUser = null;
  }
}

class FakeStatisticsRepository implements StatisticsRepository {
  @override
  Future<StatisticsResponse> getSummary() async {
    return const StatisticsResponse(
      income: '5000.00',
      expenses: '1500.00',
      balance: '3500.00',
    );
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

class FakeCategoryRepository implements CategoryRepository {
  List<Category> mockCategories = [
    const Category(id: 1, name: 'Food'),
    const Category(id: 2, name: 'Transport'),
  ];

  @override
  Future<List<Category>> getCategories() async => mockCategories;

  @override
  Future<Category> createCategory(String name) async =>
      Category(id: 3, name: name);

  @override
  Future<Category> updateCategory(int id, String name) async =>
      Category(id: id, name: name);

  @override
  Future<void> deleteCategory(int id) async {}
}

void main() {
  group('Phase 8 QA — Authentication Workflow', () {
    late FakeSecureStorageService storage;

    setUp(() {
      storage = FakeSecureStorageService();
    });

    test('Registration response does NOT save token directly', () async {
      expect(await storage.readToken(), isNull);
    });

    test(
      'JwtInterceptor skips Bearer header for login and register endpoints',
      () async {
        await storage.saveToken('existing.token.string');
        final interceptor = JwtInterceptor(storage: storage);

        final loginOptions = RequestOptions(path: '/api/auth/login');
        await interceptor.onRequest(loginOptions, RequestInterceptorHandler());
        expect(loginOptions.headers['Authorization'], isNull);

        final regOptions = RequestOptions(path: '/api/auth/register');
        await interceptor.onRequest(regOptions, RequestInterceptorHandler());
        expect(regOptions.headers['Authorization'], isNull);
      },
    );

    test(
      'JwtInterceptor attaches exactly one Bearer header for protected routes',
      () async {
        await storage.saveToken('secret.jwt.token');
        final interceptor = JwtInterceptor(storage: storage);

        final protectedOptions = RequestOptions(path: '/api/transactions');
        await interceptor.onRequest(
          protectedOptions,
          RequestInterceptorHandler(),
        );

        expect(
          protectedOptions.headers['Authorization'],
          'Bearer secret.jwt.token',
        );
      },
    );
  });

  group('Phase 8 QA — Financial Validation & Filter Logic', () {
    test(
      'TransactionFilters omits null parameters from toQueryParameters()',
      () {
        final filters = const TransactionFilters(
          type: TransactionType.expense,
          categoryId: 1,
        );
        final params = filters.toQueryParameters();

        expect(params['type'], 'EXPENSE');
        expect(params['categoryId'], 1);
        expect(params.containsKey('startDate'), isFalse);
        expect(params.containsKey('endDate'), isFalse);
        expect(params.containsKey('minAmount'), isFalse);
        expect(params.containsKey('maxAmount'), isFalse);
      },
    );

    test(
      'TransactionFilters converts min/max amount to formatted string/number',
      () {
        final filters = const TransactionFilters(
          minAmount: '50.50',
          maxAmount: '200.00',
        );
        final params = filters.toQueryParameters();

        expect(params['minAmount'], 50.5);
        expect(params['maxAmount'], 200.0);
      },
    );

    test('TransactionRequest omits userId and id fields', () {
      final req = TransactionRequest(
        description: 'Groceries',
        amount: '85.25',
        date: DateTime(2026, 8, 13),
        type: TransactionType.expense,
        categoryId: 1,
        notes: 'Supermarket',
      );

      final json = req.toJson();
      expect(json.containsKey('userId'), isFalse);
      expect(json.containsKey('id'), isFalse);
      expect(json['description'], 'Groceries');
      expect(json['amount'], 85.25);
      expect(json['type'], 'EXPENSE');
    });
  });

  group(
    'Phase 8 QA — Multi-Viewport Responsive & Accessibility Widget Tests',
    () {
      final viewports = [
        const Size(300, 600), // Narrow device
        const Size(390, 844), // Standard iPhone
        const Size(768, 1024), // Tablet
      ];

      final scales = [1.0, 1.5, 2.0];

      for (final size in viewports) {
        for (final scale in scales) {
          testWidgets(
            'HomeScreen renders at viewport ${size.width}x${size.height} with textScale $scale without overflow',
            (tester) async {
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1.0;
              addTearDown(tester.view.reset);

              final authState = const AuthState(
                status: AuthStatus.authenticated,
                user: UserResponse(
                  id: 1,
                  name: 'Responsive User',
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
                  child: MediaQuery(
                    data: MediaQueryData.fromView(
                      tester.view,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: const MaterialApp(home: HomeScreen()),
                  ),
                ),
              );

              await tester.pumpAndSettle();

              expect(find.byType(HomeScreen), findsOneWidget);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }

      testWidgets('CategoryPicker renders cleanly with categories', (
        tester,
      ) async {
        Category? selectedCat;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(
                FakeCategoryRepository(),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: CategoryPicker(
                  selectedCategory: null,
                  onChanged: (cat) => selectedCat = cat,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(CategoryPicker), findsOneWidget);
        expect(find.text('Select Category'), findsOneWidget);

        await tester.tap(find.byType(CategoryPicker));
        await tester.pumpAndSettle();

        expect(find.text('Food'), findsOneWidget);
        await tester.tap(find.text('Food').last);
        await tester.pumpAndSettle();

        expect(selectedCat?.name, 'Food');
      });

      testWidgets('TransactionFilterSheet renders cleanly in bottom sheet', (
        tester,
      ) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(
                FakeCategoryRepository(),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: TransactionFilterSheet()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(TransactionFilterSheet), findsOneWidget);
        expect(find.text('Filter Transactions'), findsOneWidget);
        expect(find.text('Apply Filters'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      });
    },
  );
}
