enum TransactionType {
  income('INCOME'),
  expense('EXPENSE');

  final String jsonValue;
  const TransactionType(this.jsonValue);

  static TransactionType fromJson(dynamic value) {
    if (value is String) {
      final upper = value.toUpperCase();
      if (upper == 'INCOME') return TransactionType.income;
      if (upper == 'EXPENSE') return TransactionType.expense;
    }
    throw FormatException('Invalid TransactionType JSON value: $value');
  }

  String toJson() => jsonValue;
}
