import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/money_utils.dart';
import 'transaction_type.dart';

class TransactionRequest {
  final String description;
  final String amount;
  final DateTime date;
  final TransactionType type;
  final int categoryId;
  final String? notes;

  const TransactionRequest({
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.categoryId,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final parsedNum = num.tryParse(amount);
    return {
      'description': description,
      'amount': parsedNum ?? amount,
      'date': AppDateUtils.formatDateToYmd(date),
      'type': type.toJson(),
      'categoryId': categoryId,
      if (notes != null) 'notes': notes,
    };
  }

  factory TransactionRequest.fromJson(Map<String, dynamic> json) {
    return TransactionRequest(
      description: json['description'] as String? ?? '',
      amount: MoneyUtils.parseMoney(json['amount']),
      date: AppDateUtils.parseYmdDate(json['date']),
      type: TransactionType.fromJson(json['type']),
      categoryId: (json['categoryId'] as num).toInt(),
      notes: json['notes'] as String?,
    );
  }
}
