import '../../../../core/utils/money_utils.dart';

class StatisticsResponse {
  final String income;
  final String expenses;
  final String balance;

  const StatisticsResponse({
    required this.income,
    required this.expenses,
    required this.balance,
  });

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) {
    return StatisticsResponse(
      income: MoneyUtils.parseMoney(json['income']),
      expenses: MoneyUtils.parseMoney(json['expenses']),
      balance: MoneyUtils.parseMoney(json['balance']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'income': num.tryParse(income) ?? income,
      'expenses': num.tryParse(expenses) ?? expenses,
      'balance': num.tryParse(balance) ?? balance,
    };
  }
}
