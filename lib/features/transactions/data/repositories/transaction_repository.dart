import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/paginated_response.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/transaction.dart';
import '../models/transaction_filters.dart';
import '../models/transaction_request.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TransactionRepository(dio: dio);
});

class TransactionRepository {
  final Dio _dio;

  TransactionRepository({required Dio dio}) : _dio = dio;

  /// GET /api/transactions?page=0&size=10&sort=date,desc
  Future<PaginatedResponse<Transaction>> getTransactions({
    int page = 0,
    int size = 10,
    String sort = 'date,desc',
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.transactions,
        queryParameters: {'page': page, 'size': size, 'sort': sort},
      );

      if (response.statusCode == 200) {
        return PaginatedResponse<Transaction>.fromJson(
          response.data as Map<String, dynamic>,
          (item) => Transaction.fromJson(item as Map<String, dynamic>),
        );
      }

      throw const ApiException(
        message: 'Failed to load transactions.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /api/transactions/search?type=...&categoryId=...
  Future<PaginatedResponse<Transaction>> searchTransactions(
    TransactionFilters filters, {
    int page = 0,
    int size = 10,
    String sort = 'date,desc',
  }) async {
    try {
      final queryParams = filters.toQueryParameters();
      queryParams['page'] = page;
      queryParams['size'] = size;
      queryParams['sort'] = sort;

      final response = await _dio.get(
        ApiEndpoints.transactionsSearch,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return PaginatedResponse<Transaction>.fromJson(
          response.data as Map<String, dynamic>,
          (item) => Transaction.fromJson(item as Map<String, dynamic>),
        );
      }

      throw const ApiException(
        message: 'Failed to search transactions.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/transactions
  Future<Transaction> createTransaction(TransactionRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.transactions,
        data: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Transaction.fromJson(response.data as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Failed to create transaction.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /api/transactions/{id}
  Future<Transaction> updateTransaction(
    int id,
    TransactionRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.transactions}/$id',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return Transaction.fromJson(response.data as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Failed to update transaction.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /api/transactions/{id}
  Future<void> deleteTransaction(int id) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.transactions}/$id');

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      }

      throw const ApiException(
        message: 'Failed to delete transaction.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
