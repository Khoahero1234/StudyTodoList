// lib/features/study_room/providers/messages_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/auth/token_provider.dart';
import '../../../core/socket/socket_service.dart'; // optional if using socket for real-time
import 'package:dio/dio.dart';
import 'conversation_provider.dart'; // provides dioProvider

/// Fetches the list of messages for a given conversation ID from the backend.
final messagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) async {
  final dio = ref.watch(dioProvider);
  final token = await ref.watch(authTokenProvider.future);
  final response = await dio.get('/conversations/$conversationId/messages',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  final List data = response.data as List;
  return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
});
