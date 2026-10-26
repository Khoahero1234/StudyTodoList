// lib/features/pomodoro/services/pomodoro_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PomodoroService {
  // Tự động chuyển đổi URL tùy theo nền tảng bạn đang chạy app
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1/pomodoro';
    } else {
      return 'http://10.0.2.2:3000/api/v1/pomodoro';
    }
  }

  // 1. Gọi API bắt đầu phiên Pomodoro
  static Future<Map<String, dynamic>?> startSession(String userId, {String? taskId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/start'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'taskId': taskId,
          'focusMinutes': 25,
          'breakMinutes': 5,
          'sessionsPlanned': 4,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data']; // Trả về thông tin session vừa tạo kèm ID
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khởi tạo Pomodoro: $e');
      return null;
    }
  }

  // 2. Gọi API kết thúc phiên Pomodoro để lưu thống kê & cộng điểm XP/Token
  static Future<bool> endSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/end'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionId': sessionId,
          'sessionsCompleted': 1,
          'xpEarned': 10,
          'tokenEarned': 5,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi kết thúc Pomodoro: $e');
      return false;
    }
  }
}