import 'package:dio/dio.dart';
import 'package:expense_tracker_flutter/core/models/paginated_response.dart';
import 'package:expense_tracker_flutter/core/network/api_endpoints.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker_flutter/features/categories/data/models/category.dart';
import 'package:expense_tracker_flutter/features/categories/presentation/providers/category_provider.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction_filters.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction_request.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction_type.dart';
import 'package:expense_tracker_flutter/features/transactions/data/repositories/transaction_repository.dart';
import 'package:expense_tracker_flutter/features/transactions/presentation/screens/transaction_list_screen.dart';
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

class FakeTransactionRepository implements TransactionRepository {
  List<Transaction> mockTransactions = [
    Transaction(
      id: 1,
      description: 'Salary',
      amount: '3000.00',
      date: DateTime(2026, 8, 1),
      type: TransactionType.income,
      category: const Category(id: 1, name: 'Job'),
      notes: 'Monthly pay',
    ),
    Transaction(
      id: 2,
      description: 'Groceries',
      amount: '120.50',
      date: DateTime(2026, 8, 2),
      type: TransactionType.expense,
      category: const Category(id: 2, name: 'Food'),
    ),
  ];

  @override
  Future<PaginatedResponse<Transaction>> getTransactions({
    int page = 0,
    int size = 10,
    String sort = 'date,desc',
  }) async {
    return _toPaginated(mockTransactions, page, size);
  }

  @override
  Future<PaginatedResponse<Transaction>> searchTransactions(
    TransactionFilters filters, {
    int page = 0,
    int size = 10,
    String sort = 'date,desc',
  }) async {
    var filtered = mockTransactions;
    if (filters.type != null) {
      filtered = filtered.where((t) => t.type == filters.type).toList();
    }
    return _toPaginated(filtered, page, size);
  }

  @override
  Future<Transaction> createTransaction(TransactionRequest request) async {
    final newId = mockTransactions.length + 1;
    final created = Transaction(
      id: newId,
      description: request.description,
      amount: request.amount,
      date: request.date,
      type: request.type,
      category: Category(
        id: request.categoryId,
        name: 'Category ${request.categoryId}',
      ),
      notes: request.notes,
    );
    mockTransactions.insert(0, created);
    return created;
  }

  @override
  Future<Transaction> updateTransaction(
    int id,
    TransactionRequest request,
  ) async {
    final updated = Transaction(
      id: id,
      description: request.description,
      amount: request.amount,
      date: request.date,
      type: request.type,
      category: Category(
        id: request.categoryId,
        name: 'Category ${request.categoryId}',
      ),
      notes: request.notes,
    );
    mockTransactions = mockTransactions
        .map((t) => t.id == id ? updated : t)
        .toList();
    return updated;
  }

  @override
  Future<void> deleteTransaction(int id) async {
    mockTransactions.removeWhere((t) => t.id == id);
  }

  PaginatedResponse<Transaction> _toPaginated(
    List<Transaction> list,
    int page,
    int size,
  ) {
    return PaginatedResponse<Transaction>(
      content: list,
      pageNumber: page,
      pageSize: size,
      totalElements: list.length,
      totalPages: 1,
      isFirst: page == 0,
      isLast: true,
      numberOfElements: list.length,
      isEmpty: list.isEmpty,
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

class FakeCategoryNotifier extends StateNotifier<CategoryState>
    implements CategoryNotifier {
  FakeCategoryNotifier(super.state);
  @override
  Future<bool> createCategory(String name) async => true;
  @override
  Future<bool> deleteCategory(int id) async => true;
  @override
  Future<void> loadCategories() async {}
  @override
  Future<bool> updateCategory(int id, String name) async => true;
}

void main() {
  group('TransactionFilters Tests', () {
    test('Validates start date after end date', () {
      final filters = TransactionFilters(
        startDate: DateTime(2026, 8, 10),
        endDate: DateTime(2026, 8, 5),
      );
      expect(filters.validate(), contains('cannot be after'));
    });

    test('Validates min amount > max amount', () {
      final filters = const TransactionFilters(
        minAmount: '500',
        maxAmount: '100',
      );
      expect(filters.validate(), contains('cannot exceed'));
    });

    test('toQueryParameters omits null values', () {
      final filters = const TransactionFilters(
        type: TransactionType.expense,
        minAmount: '50.00',
      );
      final params = filters.toQueryParameters();

      expect(params['type'], 'EXPENSE');
      expect(params['minAmount'], 50.0);
      expect(params.containsKey('categoryId'), isFalse);
      expect(params.containsKey('startDate'), isFalse);
    });
  });

  group('TransactionRepository Unit Tests', () {
    late Dio dio;

    setUp(() {
      dio = Dio(
        BaseOptions(baseUrl: 'https://expense-tracker-api-x8nw.onrender.com'),
      );
    });

    test('getTransactions parses Spring Page JSON correctly', () async {
      dio.httpClientAdapter = FakeDioAdapter()
        ..onRequest = (options) {
          expect(options.path, ApiEndpoints.transactions);
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: '''
            {
              "content": [
                {
                  "id": 1,
                  "description": "Lunch",
                  "amount": 25.50,
                  "date": "2026-08-13",
                  "type": "EXPENSE",
                  "category": {"id": 1, "name": "Food"},
                  "notes": "Team lunch"
                }
              ],
              "number": 0,
              "size": 10,
              "totalElements": 1,
              "totalPages": 1,
              "first": true,
              "last": true,
              "numberOfElements": 1,
              "empty": false
            }
            ''',
          );
        };

      final repo = TransactionRepository(dio: dio);
      final paginated = await repo.getTransactions();

      expect(paginated.content.length, 1);
      expect(paginated.content.first.description, 'Lunch');
      expect(paginated.content.first.type, TransactionType.expense);
    });
  });

  group('TransactionScreen Widget Tests', () {
    testWidgets(
      'Renders transactions list with income (+ green) and expense (- red) indicators',
      (tester) async {
        final authState = const AuthState(
          status: AuthStatus.authenticated,
          user: UserResponse(
            id: 1,
            name: 'Tester',
            email: 'test@example.com',
            role: 'USER',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => FakeAuthNotifier(authState),
              ),
              categoryStateProvider.overrideWith(
                (ref) => FakeCategoryNotifier(const CategoryState.initial()),
              ),
              transactionRepositoryProvider.overrideWithValue(
                FakeTransactionRepository(),
              ),
            ],
            child: const MaterialApp(home: TransactionListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Salary'), findsOneWidget);
        expect(find.text('+\$3000.00'), findsOneWidget);
        expect(find.text('Groceries'), findsOneWidget);
        expect(find.text('-\$120.50'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders long descriptions and category names on narrow screen without horizontal RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(300, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final repository = FakeTransactionRepository();
        repository.mockTransactions = [
          Transaction(
            id: 99,
            description:
                'Very Extremely Long Transaction Description That Might Overflow The Horizontal Bounds',
            amount: '999999.99',
            date: DateTime(2026, 8, 13),
            type: TransactionType.expense,
            category: const Category(
              id: 1,
              name: 'Very Long Category Name For Testing Layout Bounds',
            ),
            notes: 'Extra long notes string to verify truncation logic',
          ),
        ];

        final authState = const AuthState(
          status: AuthStatus.authenticated,
          user: UserResponse(
            id: 1,
            name: 'Tester',
            email: 'test@example.com',
            role: 'USER',
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => FakeAuthNotifier(authState),
              ),
              categoryStateProvider.overrideWith(
                (ref) => FakeCategoryNotifier(const CategoryState.initial()),
              ),
              transactionRepositoryProvider.overrideWithValue(repository),
            ],
            child: const MaterialApp(home: TransactionListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(TransactionListScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
