import 'package:expense_tracker_flutter/core/models/paginated_response.dart';
import 'package:expense_tracker_flutter/core/utils/money_utils.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/auth_response.dart';
import 'package:expense_tracker_flutter/features/auth/data/models/user_response.dart';
import 'package:expense_tracker_flutter/features/categories/data/models/category.dart';
import 'package:expense_tracker_flutter/features/statistics/data/models/statistics_response.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction_request.dart';
import 'package:expense_tracker_flutter/features/transactions/data/models/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth & User Response Deserialization', () {
    test(
      'UserResponse deserializes correctly for Registration (201 Created)',
      () {
        final json = {
          'id': 1,
          'name': 'Test User',
          'email': 'test@example.com',
          'role': 'USER',
        };

        final user = UserResponse.fromJson(json);

        expect(user.id, 1);
        expect(user.name, 'Test User');
        expect(user.email, 'test@example.com');
        expect(user.role, 'USER');
      },
    );

    test('AuthResponse deserializes correctly for Login (200 OK)', () {
      final json = {
        'token': 'jwt_secret_token_123',
        'tokenType': 'Bearer',
        'user': {
          'id': 2,
          'name': 'Admin User',
          'email': 'admin@example.com',
          'role': 'ADMIN',
        },
      };

      final authResponse = AuthResponse.fromJson(json);

      expect(authResponse.token, 'jwt_secret_token_123');
      expect(authResponse.tokenType, 'Bearer');
      expect(authResponse.user.id, 2);
      expect(authResponse.user.role, 'ADMIN');
    });
  });

  group('Category Deserialization', () {
    test('Category parses id and name only without type field', () {
      final json = {'id': 5, 'name': 'Groceries'};

      final category = Category.fromJson(json);

      expect(category.id, 5);
      expect(category.name, 'Groceries');
    });
  });

  group('TransactionType Enum Conversion', () {
    test('Parses uppercase INCOME and EXPENSE correctly', () {
      expect(TransactionType.fromJson('INCOME'), TransactionType.income);
      expect(TransactionType.fromJson('EXPENSE'), TransactionType.expense);
    });

    test('Throws FormatException for unknown enum values', () {
      expect(
        () => TransactionType.fromJson('INVALID_TYPE'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Money Representation & Parsing', () {
    test('Parses int, double, and String as normalized decimal String', () {
      expect(MoneyUtils.parseMoney(100), '100.00');
      expect(MoneyUtils.parseMoney(25.5), '25.50');
      expect(MoneyUtils.parseMoney('1200.75'), '1200.75');
      expect(MoneyUtils.parseMoney(null), '0.00');
    });
  });

  group('Transaction & TransactionRequest Deserialization', () {
    test('Transaction parses complete JSON with nullable notes', () {
      final json = {
        'id': 42,
        'description': 'Team Lunch',
        'amount': 45.99,
        'date': '2026-08-12',
        'type': 'EXPENSE',
        'category': {'id': 1, 'name': 'Food'},
        'notes': 'Quarterly celebration',
      };

      final tx = Transaction.fromJson(json);

      expect(tx.id, 42);
      expect(tx.description, 'Team Lunch');
      expect(tx.amount, '45.99');
      expect(tx.type, TransactionType.expense);
      expect(tx.category.name, 'Food');
      expect(tx.notes, 'Quarterly celebration');
    });

    test('Transaction handles null notes safely', () {
      final json = {
        'id': 43,
        'description': 'Salary',
        'amount': '3500.00',
        'date': '2026-08-01',
        'type': 'INCOME',
        'category': {'id': 2, 'name': 'Salary'},
        'notes': null,
      };

      final tx = Transaction.fromJson(json);

      expect(tx.id, 43);
      expect(tx.type, TransactionType.income);
      expect(tx.notes, null);
    });

    test('TransactionRequest serializes date strictly as YYYY-MM-DD', () {
      final request = TransactionRequest(
        description: 'Coffee',
        amount: '4.50',
        date: DateTime(2026, 8, 12, 14, 30),
        type: TransactionType.expense,
        categoryId: 1,
        notes: null,
      );

      final json = request.toJson();

      expect(json['date'], '2026-08-12');
      expect(json['amount'], 4.5);
      expect(json['type'], 'EXPENSE');
    });
  });

  group('StatisticsResponse Deserialization', () {
    test('Parses income, expenses, balance without totalTransactions', () {
      final json = {'income': 3500.00, 'expenses': 1200.50, 'balance': 2299.50};

      final stats = StatisticsResponse.fromJson(json);

      expect(stats.income, '3500.00');
      expect(stats.expenses, '1200.50');
      expect(stats.balance, '2299.50');
    });
  });

  group('PaginatedResponse Deserialization', () {
    test(
      'Maps Spring Data Page JSON fields (number, size, totalElements, etc.)',
      () {
        final json = {
          'content': [
            {
              'id': 10,
              'description': 'Taxi',
              'amount': 15.00,
              'date': '2026-08-10',
              'type': 'EXPENSE',
              'category': {'id': 3, 'name': 'Transport'},
              'notes': null,
            },
          ],
          'number': 0,
          'size': 10,
          'totalElements': 1,
          'totalPages': 1,
          'first': true,
          'last': true,
          'numberOfElements': 1,
          'empty': false,
        };

        final page = PaginatedResponse<Transaction>.fromJson(
          json,
          (item) => Transaction.fromJson(item as Map<String, dynamic>),
        );

        expect(page.content.length, 1);
        expect(page.pageNumber, 0);
        expect(page.pageSize, 10);
        expect(page.totalElements, 1);
        expect(page.isFirst, isTrue);
        expect(page.isLast, isTrue);
        expect(page.content.first.description, 'Taxi');
      },
    );
  });
}
