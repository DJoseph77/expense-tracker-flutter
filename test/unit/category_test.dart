import 'package:dio/dio.dart';
import 'package:expense_tracker_flutter/core/network/api_endpoints.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker_flutter/features/categories/data/models/category.dart';
import 'package:expense_tracker_flutter/features/categories/data/repositories/category_repository.dart';
import 'package:expense_tracker_flutter/features/categories/presentation/providers/category_provider.dart';
import 'package:expense_tracker_flutter/features/categories/presentation/screens/categories_screen.dart';
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

class FakeCategoryRepository implements CategoryRepository {
  late List<Category> mockCategories;

  FakeCategoryRepository() {
    mockCategories = [
      const Category(id: 1, name: 'Food'),
      const Category(id: 2, name: 'Transport'),
    ];
  }

  @override
  Future<List<Category>> getCategories() async => List.from(mockCategories);

  @override
  Future<Category> createCategory(String name) async {
    final newCat = Category(id: mockCategories.length + 1, name: name);
    mockCategories.add(newCat);
    return newCat;
  }

  @override
  Future<Category> updateCategory(int id, String name) async {
    final updated = Category(id: id, name: name);
    mockCategories = mockCategories
        .map((c) => c.id == id ? updated : c)
        .toList();
    return updated;
  }

  @override
  Future<void> deleteCategory(int id) async {
    mockCategories.removeWhere((c) => c.id == id);
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
  group('CategoryRepository Unit Tests', () {
    late Dio dio;

    setUp(() {
      dio = Dio(
        BaseOptions(baseUrl: 'https://expense-tracker-api-x8nw.onrender.com'),
      );
    });

    test('getCategories parses Category JSON list (id, name only)', () async {
      dio.httpClientAdapter = FakeDioAdapter()
        ..onRequest = (options) {
          expect(options.path, ApiEndpoints.categories);
          return Response(
            requestOptions: options,
            statusCode: 200,
            data: '[{"id":1,"name":"Food"},{"id":2,"name":"Rent"}]',
          );
        };

      final repo = CategoryRepository(dio: dio);
      final categories = await repo.getCategories();

      expect(categories.length, 2);
      expect(categories[0].id, 1);
      expect(categories[0].name, 'Food');
      expect(categories[1].name, 'Rent');
    });

    test('createCategory sends POST and parses returned Category', () async {
      dio.httpClientAdapter = FakeDioAdapter()
        ..onRequest = (options) {
          expect(options.path, ApiEndpoints.categories);
          expect(options.method, 'POST');
          expect(options.data['name'], 'Entertainment');
          return Response(
            requestOptions: options,
            statusCode: 201,
            data: '{"id":3,"name":"Entertainment"}',
          );
        };

      final repo = CategoryRepository(dio: dio);
      final created = await repo.createCategory('Entertainment');

      expect(created.id, 3);
      expect(created.name, 'Entertainment');
    });
  });

  group('CategoryNotifier Unit Tests', () {
    test('loadCategories populates categoryState', () async {
      final fakeRepo = FakeCategoryRepository();
      final notifier = CategoryNotifier(repository: fakeRepo);

      // Constructor triggers initial load
      await Future.delayed(Duration.zero);

      expect(notifier.state.categories.length, 2);
      expect(notifier.state.categories.first.name, 'Food');
    });

    test('createCategory adds item to local state list', () async {
      final fakeRepo = FakeCategoryRepository();
      final notifier = CategoryNotifier(repository: fakeRepo);
      await Future.delayed(Duration.zero);

      final success = await notifier.createCategory('Utilities');

      expect(success, isTrue);
      expect(notifier.state.categories.length, 3);
      expect(notifier.state.categories.last.name, 'Utilities');
    });
  });

  group('CategoryScreen Role-based UI Tests', () {
    testWidgets('USER role cannot see create FAB or edit/delete controls', (
      tester,
    ) async {
      final userState = const AuthState(
        status: AuthStatus.authenticated,
        user: UserResponse(
          id: 1,
          name: 'Normal User',
          email: 'user@test.com',
          role: 'USER',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(userState),
            ),
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(),
            ),
          ],
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Add Category'), findsNothing); // FAB hidden
      expect(find.byIcon(Icons.edit), findsNothing); // Edit buttons hidden
      expect(
        find.byIcon(Icons.delete_outline),
        findsNothing,
      ); // Delete buttons hidden
    });

    testWidgets('ADMIN role sees create FAB and edit/delete controls', (
      tester,
    ) async {
      final adminState = const AuthState(
        status: AuthStatus.authenticated,
        user: UserResponse(
          id: 2,
          name: 'Admin User',
          email: 'admin@test.com',
          role: 'ADMIN',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => FakeAuthNotifier(adminState),
            ),
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository(),
            ),
          ],
          child: const MaterialApp(home: CategoriesScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Add Category'), findsOneWidget); // FAB visible
      expect(find.byIcon(Icons.edit), findsWidgets); // Edit buttons visible
      expect(
        find.byIcon(Icons.delete_outline),
        findsWidgets,
      ); // Delete buttons visible
    });
  });
}
