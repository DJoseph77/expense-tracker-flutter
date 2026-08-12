import 'package:flutter/foundation.dart';

import '../../../../core/utils/date_utils.dart';
import 'transaction_type.dart';

@immutable
class TransactionFilters {
  final TransactionType? type;
  final int? categoryId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? minAmount;
  final String? maxAmount;

  const TransactionFilters({
    this.type,
    this.categoryId,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  const TransactionFilters.initial()
    : type = null,
      categoryId = null,
      startDate = null,
      endDate = null,
      minAmount = null,
      maxAmount = null;

  bool get hasActiveFilters =>
      type != null ||
      categoryId != null ||
      startDate != null ||
      endDate != null ||
      (minAmount != null && minAmount!.trim().isNotEmpty) ||
      (maxAmount != null && maxAmount!.trim().isNotEmpty);

  TransactionFilters copyWith({
    TransactionType? type,
    int? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? minAmount,
    String? maxAmount,
    bool clearType = false,
    bool clearCategoryId = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return TransactionFilters(
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  /// Converts active filter fields to backend query parameters
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (type != null) {
      params['type'] = type!.toJson();
    }
    if (categoryId != null) {
      params['categoryId'] = categoryId;
    }
    if (startDate != null) {
      params['startDate'] = AppDateUtils.formatDateToYmd(startDate!);
    }
    if (endDate != null) {
      params['endDate'] = AppDateUtils.formatDateToYmd(endDate!);
    }
    if (minAmount != null && minAmount!.trim().isNotEmpty) {
      final parsed = num.tryParse(minAmount!.trim());
      params['minAmount'] = parsed ?? minAmount!.trim();
    }
    if (maxAmount != null && maxAmount!.trim().isNotEmpty) {
      final parsed = num.tryParse(maxAmount!.trim());
      params['maxAmount'] = parsed ?? maxAmount!.trim();
    }

    return params;
  }

  /// Validates filter bounds
  String? validate() {
    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
      return 'Start date cannot be after end date.';
    }

    final minVal = minAmount != null
        ? double.tryParse(minAmount!.trim())
        : null;
    final maxVal = maxAmount != null
        ? double.tryParse(maxAmount!.trim())
        : null;

    if (minVal != null && minVal < 0) {
      return 'Minimum amount cannot be negative.';
    }
    if (maxVal != null && maxVal < 0) {
      return 'Maximum amount cannot be negative.';
    }
    if (minVal != null && maxVal != null && minVal > maxVal) {
      return 'Minimum amount cannot exceed maximum amount.';
    }

    return null;
  }
}
