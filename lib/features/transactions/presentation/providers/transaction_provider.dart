import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/transaction.dart';
import '../../data/models/transaction_filters.dart';
import '../../data/models/transaction_request.dart';
import '../../data/repositories/transaction_repository.dart';

@immutable
class TransactionState {
  final List<Transaction> transactions;
  final int currentPage;
  final int totalPages;
  final int totalElements;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool isMutating;
  final TransactionFilters filters;
  final String? errorMessage;
  final String? mutationError;

  const TransactionState({
    required this.transactions,
    required this.currentPage,
    required this.totalPages,
    required this.totalElements,
    required this.isInitialLoading,
    required this.isLoadingMore,
    required this.isMutating,
    required this.filters,
    this.errorMessage,
    this.mutationError,
  });

  const TransactionState.initial()
    : transactions = const [],
      currentPage = 0,
      totalPages = 0,
      totalElements = 0,
      isInitialLoading = false,
      isLoadingMore = false,
      isMutating = false,
      filters = const TransactionFilters.initial(),
      errorMessage = null,
      mutationError = null;

  bool get hasMore => currentPage < totalPages - 1;

  TransactionState copyWith({
    List<Transaction>? transactions,
    int? currentPage,
    int? totalPages,
    int? totalElements,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? isMutating,
    TransactionFilters? filters,
    String? errorMessage,
    String? mutationError,
    bool clearError = false,
    bool clearMutationError = false,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalElements: totalElements ?? this.totalElements,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isMutating: isMutating ?? this.isMutating,
      filters: filters ?? this.filters,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      mutationError: clearMutationError
          ? null
          : (mutationError ?? this.mutationError),
    );
  }
}

final transactionStateProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
      final repository = ref.watch(transactionRepositoryProvider);
      return TransactionNotifier(repository: repository);
    });

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository _repository;
  static const int _pageSize = 10;

  TransactionNotifier({required TransactionRepository repository})
    : _repository = repository,
      super(const TransactionState.initial()) {
    loadInitialTransactions();
  }

  /// Loads page 0 of transactions using active filters
  Future<void> loadInitialTransactions() async {
    if (!mounted) return;
    state = state.copyWith(isInitialLoading: true, clearError: true);

    try {
      final response = state.filters.hasActiveFilters
          ? await _repository.searchTransactions(
              state.filters,
              page: 0,
              size: _pageSize,
            )
          : await _repository.getTransactions(page: 0, size: _pageSize);

      if (!mounted) return;
      state = state.copyWith(
        isInitialLoading: false,
        transactions: response.content,
        currentPage: response.pageNumber,
        totalPages: response.totalPages,
        totalElements: response.totalElements,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      state = state.copyWith(isInitialLoading: false, errorMessage: e.message);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage:
            'An unexpected error occurred while loading transactions.',
      );
    }
  }

  /// Loads the next page of transactions and appends non-duplicate items
  Future<void> loadNextPage() async {
    if (!mounted) return;
    if (state.isLoadingMore || !state.hasMore || state.isInitialLoading) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    try {
      final response = state.filters.hasActiveFilters
          ? await _repository.searchTransactions(
              state.filters,
              page: nextPage,
              size: _pageSize,
            )
          : await _repository.getTransactions(page: nextPage, size: _pageSize);

      if (!mounted) return;

      final existingIds = state.transactions.map((t) => t.id).toSet();
      final newUniqueItems = response.content
          .where((t) => !existingIds.contains(t.id))
          .toList();
      final updatedList = [...state.transactions, ...newUniqueItems];

      state = state.copyWith(
        isLoadingMore: false,
        transactions: updatedList,
        currentPage: response.pageNumber,
        totalPages: response.totalPages,
        totalElements: response.totalElements,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Refreshes the transactions list (re-fetches page 0)
  Future<void> refresh() async {
    await loadInitialTransactions();
  }

  /// Applies active search filters and re-loads page 0
  Future<bool> applyFilters(TransactionFilters newFilters) async {
    final validationError = newFilters.validate();
    if (validationError != null) {
      if (mounted) {
        state = state.copyWith(errorMessage: validationError);
      }
      return false;
    }

    if (!mounted) return false;
    state = state.copyWith(
      filters: newFilters,
      currentPage: 0,
      clearError: true,
    );
    await loadInitialTransactions();
    return true;
  }

  /// Resets search filters and re-loads page 0
  Future<void> clearFilters() async {
    if (!mounted) return;
    state = state.copyWith(
      filters: const TransactionFilters.initial(),
      currentPage: 0,
      clearError: true,
    );
    await loadInitialTransactions();
  }

  /// Creates a new transaction via POST /api/transactions
  Future<bool> createTransaction(TransactionRequest request) async {
    if (!mounted || state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);

    try {
      await _repository.createTransaction(request);
      if (!mounted) return true;
      state = state.copyWith(isMutating: false, clearMutationError: true);
      await loadInitialTransactions();
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isMutating: false, mutationError: e.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isMutating: false,
        mutationError: 'Failed to create transaction.',
      );
      return false;
    }
  }

  /// Updates an existing transaction via PUT /api/transactions/{id}
  Future<bool> updateTransaction(int id, TransactionRequest request) async {
    if (!mounted || state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);

    try {
      final updated = await _repository.updateTransaction(id, request);
      if (!mounted) return true;

      final updatedList = state.transactions
          .map((t) => t.id == id ? updated : t)
          .toList();

      state = state.copyWith(
        isMutating: false,
        transactions: updatedList,
        clearMutationError: true,
      );
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isMutating: false, mutationError: e.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isMutating: false,
        mutationError: 'Failed to update transaction.',
      );
      return false;
    }
  }

  /// Deletes a transaction via DELETE /api/transactions/{id}
  Future<bool> deleteTransaction(int id) async {
    if (!mounted || state.isMutating) return false;
    state = state.copyWith(isMutating: true, clearMutationError: true);

    try {
      await _repository.deleteTransaction(id);
      if (!mounted) return true;

      final updatedList = state.transactions.where((t) => t.id != id).toList();
      final newTotal = state.totalElements > 0 ? state.totalElements - 1 : 0;

      state = state.copyWith(
        isMutating: false,
        transactions: updatedList,
        totalElements: newTotal,
        clearMutationError: true,
      );
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isMutating: false, mutationError: e.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isMutating: false,
        mutationError: 'Failed to delete transaction.',
      );
      return false;
    }
  }

  /// Retries loading initial transactions
  Future<void> retry() async {
    await loadInitialTransactions();
  }
}
