import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';

@immutable
class CategoryState {
  final bool isLoading;
  final bool isMutating;
  final List<Category> categories;
  final String? errorMessage;
  final String? mutationError;

  const CategoryState({
    required this.isLoading,
    required this.isMutating,
    required this.categories,
    this.errorMessage,
    this.mutationError,
  });

  const CategoryState.initial()
    : isLoading = false,
      isMutating = false,
      categories = const [],
      errorMessage = null,
      mutationError = null;

  CategoryState copyWith({
    bool? isLoading,
    bool? isMutating,
    List<Category>? categories,
    String? errorMessage,
    String? mutationError,
    bool clearError = false,
    bool clearMutationError = false,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      categories: categories ?? this.categories,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mutationError: clearMutationError
          ? null
          : (mutationError ?? this.mutationError),
    );
  }
}

final categoryStateProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
      final repository = ref.watch(categoryRepositoryProvider);
      return CategoryNotifier(repository: repository);
    });

class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository _repository;

  CategoryNotifier({required CategoryRepository repository})
    : _repository = repository,
      super(const CategoryState.initial()) {
    loadCategories();
  }

  /// Fetches all categories from GET /api/categories
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final list = await _repository.getCategories();
      state = state.copyWith(
        isLoading: false,
        categories: list,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred while loading categories.',
      );
    }
  }

  /// Creates a category via POST /api/categories (ADMIN only)
  Future<bool> createCategory(String name) async {
    if (state.isMutating) return false;

    state = state.copyWith(isMutating: true, clearMutationError: true);

    try {
      final newCategory = await _repository.createCategory(name);
      final updatedList = [...state.categories, newCategory];

      state = state.copyWith(
        isMutating: false,
        categories: updatedList,
        clearMutationError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isMutating: false,
        mutationError: 'Failed to create category.',
      );
      return false;
    }
  }

  /// Updates a category via PUT /api/categories/{id} (ADMIN only)
  Future<bool> updateCategory(int id, String name) async {
    if (state.isMutating) return false;

    state = state.copyWith(isMutating: true, clearMutationError: true);

    try {
      final updated = await _repository.updateCategory(id, name);
      final updatedList = state.categories
          .map((c) => c.id == id ? updated : c)
          .toList();

      state = state.copyWith(
        isMutating: false,
        categories: updatedList,
        clearMutationError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isMutating: false,
        mutationError: 'Failed to update category.',
      );
      return false;
    }
  }

  /// Deletes a category via DELETE /api/categories/{id} (ADMIN only)
  Future<bool> deleteCategory(int id) async {
    if (state.isMutating) return false;

    state = state.copyWith(isMutating: true, clearMutationError: true);

    try {
      await _repository.deleteCategory(id);
      final updatedList = state.categories.where((c) => c.id != id).toList();

      state = state.copyWith(
        isMutating: false,
        categories: updatedList,
        clearMutationError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isMutating: false, mutationError: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isMutating: false,
        mutationError: 'Failed to delete category.',
      );
      return false;
    }
  }
}
