class MoneyUtils {
  MoneyUtils._();

  /// Parses a monetary value from int, double, or String and returns a normalized
  /// decimal String formatted to 2 decimal places (e.g. "25.50").
  /// Avoids performing binary floating-point financial calculations.
  static String parseMoney(dynamic val) {
    if (val == null) return '0.00';
    if (val is int) {
      return val.toDouble().toStringAsFixed(2);
    }
    if (val is double) {
      return val.toStringAsFixed(2);
    }
    if (val is String) {
      final parsed = double.tryParse(val);
      if (parsed == null) return '0.00';
      return parsed.toStringAsFixed(2);
    }
    return '0.00';
  }
}
