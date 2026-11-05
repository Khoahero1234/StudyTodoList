// lib/features/pomodoro/services/pomodoro_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';

class PomodoroService {
  static String get baseUrl => '${AppConstants.baseUrl}/pomodoro';

  // 1. Gọi API bắt đầu phiên Pomodoro
  static Future<Map<String, dynamic>?> startSession(
    String userId, {
    String? taskId,
    int focusMinutes = 25,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'taskId': taskId,
          'focusMinutes': focusMinutes,
          'breakMinutes': 5,
          'sessionsPlanned': 4,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khởi tạo Pomodoro: $e');
      return null;
    }
  }

  // 2. Gọi API kết thúc phiên Pomodoro để lưu thống kê, cộng Token & kiểm tra nhiệm vụ tự động
  static Future<Map<String, dynamic>?> endSession(
    String sessionId, {
    int xpEarned = 25,
    int tokenEarned = 15,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'sessionsCompleted': 1,
          'xpEarned': xpEarned,
          'tokenEarned': tokenEarned,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi kết thúc Pomodoro: $e');
      return null;
    }
  }
}
