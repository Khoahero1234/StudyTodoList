// lib/features/pomodoro/services/stats_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StatsService {
  // Tự động chuyển đổi URL tùy theo nền tảng bạn đang chạy app
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1/stats';
    } else {
      return 'http://10.0.2.2:3000/api/v1/stats';
    }
  }

  // Lấy báo cáo năng suất 7 ngày gần nhất
  static Future<Map<String, dynamic>?> getWeeklyStats(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weekly/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']; // Trả về dailyStats và weeklySummary
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi lấy thống kê năng suất: $e');
      return null;
    }
  }
}