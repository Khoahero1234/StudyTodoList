// lib/core/constants/app_constants.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  AppConstants._();

  static const String appName = 'StudyTodoList';
  static const String appVersion = '1.0.0';

  // API Base URL
  // - Android Emulator: 10.0.2.2 trỏ trực tiếp về localhost của máy tính (Windows) mà không cần adb reverse
  // - iOS Simulator / Web / Desktop: localhost:3000
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

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
