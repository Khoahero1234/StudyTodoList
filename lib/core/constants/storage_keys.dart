// lib/core/constants/storage_keys.dart

class StorageKeys {
  StorageKeys._();

  // Secure Storage keys
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';

  // SQLite table names
  static const String tableUsers = 'users';
  static const String tableTasks = 'tasks';
  static const String tableCategories = 'task_categories';
  static const String tableNotifications = 'notifications';
  static const String tablePreferences = 'preferences';

  // Preference keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefFocusDuration = 'focus_duration';
  static const String prefShortBreak = 'short_break';
  static const String prefLongBreak = 'long_break';
  static const String prefPomodoroSessions = 'pomodoro_sessions';
  static const String prefNotificationsEnabled = 'notifications_enabled';
}
