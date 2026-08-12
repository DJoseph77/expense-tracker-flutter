class AppDateUtils {
  AppDateUtils._();

  /// Formats a DateTime as YYYY-MM-DD string strictly.
  static String formatDateToYmd(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parses a YYYY-MM-DD string into a DateTime.
  static DateTime parseYmdDate(dynamic val) {
    if (val is String && val.isNotEmpty) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }
}
