/// Application Configuration
class AppConfig {
  AppConfig._();

  static const String appName = 'Servino';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Environment
  static const bool isProduction = true;
  static const bool enableLogging = true;

  // API Configuration
  static String get baseUrl {
    return isProduction
        ? 'https://walidghubara.online/backend-servino/api/'
        : 'https://walidghubara.online/backend-servino/api/';
  }
}
