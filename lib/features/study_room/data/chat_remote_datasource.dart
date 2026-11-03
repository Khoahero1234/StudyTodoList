// lib/features/study_room/data/chat_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chat_conversation.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class ChatRemoteDataSource {
  final DioClient _dioClient;

  ChatRemoteDataSource(this._dioClient);

  Future<List<ChatConversation>> getConversations({String? currentUserId}) async {
    final response = await _dioClient.get('/chats/conversations');
    final data = response.data;
    List rawList = [];
    if (data is Map<String, dynamic> && data['data'] is List) {
      rawList = data['data'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList
        .map((e) => ChatConversation.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {String? currentUserId}) async {
    final response = await _dioClient.get('/chats/conversations/$conversationId/messages');
    final data = response.data;
    List rawList = [];
    if (data is Map<String, dynamic> && data['data'] is List) {
      rawList = data['data'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
  }

  Future<ChatMessage> sendMessage(String conversationId, String content, {String? currentUserId}) async {
    final response = await _dioClient.post(
      '/chats/conversations/$conversationId/messages',
      data: {'content': content},
    );
    final data = response.data;
    final Map<String, dynamic> json = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data is Map<String, dynamic> ? data : {});
    return ChatMessage.fromJson(json, currentUserId: currentUserId);
  }

  Future<ChatConversation> createDirectConversation(String otherUserId, {String? currentUserId}) async {
    final response = await _dioClient.post(
      '/chats/conversations',
      data: {
        'participantIds': [otherUserId],
        'type': 'DIRECT',
      },
    );
    final data = response.data;
    final Map<String, dynamic> json = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data is Map<String, dynamic> ? data : {});
    return ChatConversation.fromJson(json, currentUserId: currentUserId);
  }

  Future<ChatConversation> createGroupConversation(String name, List<String> memberIds, {String? currentUserId}) async {
    final response = await _dioClient.post(
      '/chats/conversations',
      data: {
        'name': name,
        'participantIds': memberIds,
        'type': 'GROUP',
      },
    );
    final data = response.data;
    final Map<String, dynamic> json = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data is Map<String, dynamic> ? data : {});
    return ChatConversation.fromJson(json, currentUserId: currentUserId);
  }
}

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ChatRemoteDataSource(dioClient);
});

