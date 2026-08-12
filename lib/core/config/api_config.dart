class ApiConfig {
  ApiConfig._();

  static const String _defaultUrl =
      'https://expense-tracker-api-x8nw.onrender.com';

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return _defaultUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 90);
  static const Duration receiveTimeout = Duration(seconds: 90);
  static const Duration sendTimeout = Duration(seconds: 30);
}
