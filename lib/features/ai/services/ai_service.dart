// lib/features/ai/services/ai_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  // Tự động chuyển đổi URL tùy theo nền tảng bạn đang chạy app
  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1/ai';
    } else {
      return 'http://10.0.2.2:3000/api/v1/ai';
    }
  }

  // Hàm alias tương thích trực tiếp với ai_chat_dialog.dart
  Future<Map<String, dynamic>?> processTaskWithAI(String prompt) async {
    return await processTask(prompt);
  }

  // 1. Gửi yêu cầu tự nhiên để phân tích và tạo task
  Future<Map<String, dynamic>?> processTask(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/process-task'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data; // Trả về nguyên cục JSON chứa trường 'data' để ai_chat_dialog đọc được response['data']
      } else {
        debugPrint('Lỗi server: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Lỗi kết nối API AI: $e');
      return null;
    }
  }

  // 2. Lấy lời khuyên năng suất / daily planner từ AI
  Future<String?> getRecommendation(List<dynamic> tasks, String userQuery) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommendation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tasks': tasks, 'userQuery': userQuery}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['recommendation'];
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Lỗi kết nối Recommendation: $e');
      return null;
    }
  }
}