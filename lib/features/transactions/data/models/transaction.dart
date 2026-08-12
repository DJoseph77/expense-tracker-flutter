import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../categories/data/models/category.dart';
import 'transaction_type.dart';

class Transaction {
  final int id;
  final String description;
  final String amount;
  final DateTime date;
  final TransactionType type;
  final Category category;
  final String? notes;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
    this.notes,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: (json['id'] as num).toInt(),
      description: json['description'] as String? ?? '',
      amount: MoneyUtils.parseMoney(json['amount']),
      date: AppDateUtils.parseYmdDate(json['date']),
      type: TransactionType.fromJson(json['type']),
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': num.tryParse(amount) ?? amount,
      'date': AppDateUtils.formatDateToYmd(date),
      'type': type.toJson(),
      'category': category.toJson(),
      if (notes != null) 'notes': notes,
    };
  }
}
