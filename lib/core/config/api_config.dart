class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://expense-tracker-api-x8nw.onrender.com';
  static const Duration connectTimeout = Duration(seconds: 90);
  static const Duration receiveTimeout = Duration(seconds: 90);
  static const Duration sendTimeout = Duration(seconds: 30);
}
