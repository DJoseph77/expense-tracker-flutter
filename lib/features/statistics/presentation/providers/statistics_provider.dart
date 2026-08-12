import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/statistics_response.dart';
import '../../data/repositories/statistics_repository.dart';

@immutable
class StatisticsState {
  final StatisticsResponse? summary;
  final bool isInitialLoading;
  final bool isRefreshing;
  final String? errorMessage;

  const StatisticsState({
    this.summary,
    required this.isInitialLoading,
    required this.isRefreshing,
    this.errorMessage,
  });

  const StatisticsState.initial()
    : summary = null,
      isInitialLoading = false,
      isRefreshing = false,
      errorMessage = null;

  StatisticsState copyWith({
    StatisticsResponse? summary,
    bool? isInitialLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatisticsState(
      summary: summary ?? this.summary,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final statisticsStateProvider =
    StateNotifierProvider<StatisticsNotifier, StatisticsState>((ref) {
      final repository = ref.watch(statisticsRepositoryProvider);
      return StatisticsNotifier(repository: repository);
    });

class StatisticsNotifier extends StateNotifier<StatisticsState> {
  final StatisticsRepository _repository;

  StatisticsNotifier({required StatisticsRepository repository})
    : _repository = repository,
      super(const StatisticsState.initial()) {
    loadInitialSummary();
  }

  /// Initial load of statistics summary
  Future<void> loadInitialSummary() async {
    if (!mounted) return;
    if (state.isInitialLoading) return;

    state = state.copyWith(
      isInitialLoading: state.summary == null,
      clearError: true,
    );

    try {
      final summary = await _repository.getSummary();
      if (!mounted) return;

      state = state.copyWith(
        summary: summary,
        isInitialLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        errorMessage: e.message,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        errorMessage: 'Failed to load statistics summary.',
      );
    }
  }

  /// Pull-to-refresh statistics summary (preserves existing summary if refresh fails)
  Future<void> refresh() async {
    if (!mounted) return;
    if (state.isRefreshing || state.isInitialLoading) return;

    state = state.copyWith(isRefreshing: true, clearError: true);

    try {
      final updatedSummary = await _repository.getSummary();
      if (!mounted) return;

      state = state.copyWith(
        summary: updatedSummary,
        isRefreshing: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // Preserve existing summary on refresh failure
      state = state.copyWith(isRefreshing: false, errorMessage: e.message);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh statistics summary.',
      );
    }
  }

  /// Manual retry after error
  Future<void> retry() async {
    await loadInitialSummary();
  }
}
