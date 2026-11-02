// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'StudyTodoList';
  static const String appVersion = '1.0.0';

  // API
  // Physical Android device over USB: forward port 3000 with `adb reverse`.
  // static const String baseUrl = 'http://192.168.56.1:3000/api/v1';
  static const String baseUrl = 'http://localhost:3000/api/v1'; // iOS simulator

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Pagination
  static const int pageSize = 20;

  // Token system
  static const String tokenCurrencySymbol = '🪙';
  static const String tokenCurrencyName = 'Tokens';

  // Pomodoro defaults
  static const int defaultFocusMinutes = 25;
  static const int defaultShortBreakMinutes = 5;
  static const int defaultLongBreakMinutes = 15;
  static const int defaultPomodoroSessions = 4;

  // Streak rewards
  static const Map<int, int> streakTokenRewards = {
    1: 10,
    3: 30,
    7: 70,
    14: 150,
    30: 500,
  };

  // Task priority colors (hex)
  static const Map<String, int> priorityColors = {
    'low': 0xFF4CAF50,
    'medium': 0xFFFF9800,
    'high': 0xFFF44336,
    'urgent': 0xFF9C27B0,
  };
}
