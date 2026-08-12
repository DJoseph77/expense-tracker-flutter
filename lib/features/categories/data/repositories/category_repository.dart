import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return CategoryRepository(dio: dio);
});

class CategoryRepository {
  final Dio _dio;

  CategoryRepository({required Dio dio}) : _dio = dio;

  /// GET /api/categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);

      if (response.statusCode == 200) {
        final rawList = response.data as List<dynamic>? ?? [];
        return rawList
            .map((item) => Category.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw const ApiException(
        message: 'Failed to load categories.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/categories (ADMIN only)
  Future<Category> createCategory(String name) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.categories,
        data: {'name': name.trim()},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Category.fromJson(response.data as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Failed to create category.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /api/categories/{id} (ADMIN only)
  Future<Category> updateCategory(int id, String name) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.categories}/$id',
        data: {'name': name.trim()},
      );

      if (response.statusCode == 200) {
        return Category.fromJson(response.data as Map<String, dynamic>);
      }

      throw const ApiException(
        message: 'Failed to update category.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// DELETE /api/categories/{id} (ADMIN only)
  Future<void> deleteCategory(int id) async {
    try {
      final response = await _dio.delete('${ApiEndpoints.categories}/$id');

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      }

      throw const ApiException(
        message: 'Failed to delete category.',
        type: ApiExceptionType.badRequest,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
