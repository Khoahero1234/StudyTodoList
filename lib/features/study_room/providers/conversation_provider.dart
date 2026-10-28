// lib/features/study_room/providers/conversation_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/models/chat_conversation.dart';
import '../../../core/auth/token_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  // Adjust base URL if your backend runs elsewhere
  return Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
});

/// Provides the list of conversations for the current user.
final conversationProvider = FutureProvider<List<ChatConversation>>((ref) async {
  final dio = ref.watch(dioProvider);
  final token = await ref.watch(authTokenProvider.future);
  final response = await dio.get('/conversations',
      options: Options(headers: {'Authorization': 'Bearer $token'}));
  final List data = response.data as List;
  return data.map((e) => ChatConversation.fromJson(e)).toList();
});
