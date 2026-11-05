// lib/features/study_room/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/socket/socket_service.dart';
import '../../../core/models/chat_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/chat_remote_datasource.dart';
import 'conversation_provider.dart';

/// Manages the list of ChatMessage for a specific conversation.
class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRemoteDataSource _remoteDataSource;
  final SocketService _socket;
  final String conversationId;
  final String? currentUserId;
  final Ref _ref;

  ChatNotifier(
    this._remoteDataSource,
    this._socket,
    this.conversationId,
    this.currentUserId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. Fetch historical messages
      final messages = await _remoteDataSource.getMessages(
        conversationId,
        currentUserId: currentUserId,
      );
      state = AsyncValue.data(messages);

      // 2. Join conversation room on WebSocket
      _socket.joinConversation(conversationId);

      // 3. Listen for incoming messages
      _socket.onChatMessage(_handleIncoming);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _handleIncoming(dynamic data) {
    if (data is Map<String, dynamic>) {
      final msgConvId = data['conversationId']?.toString();
      if (msgConvId != null && msgConvId == conversationId) {
        final newMsg = ChatMessage.fromJson(data, currentUserId: currentUserId);
        final currentList = state.valueOrNull ?? [];
        if (!currentList.any((m) => m.id == newMsg.id)) {
          state = AsyncValue.data([...currentList, newMsg]);
        }
      }
    }
  }

  Future<void> send(String content) async {
    if (content.trim().isEmpty) return;

    try {
      // Send via REST endpoint (which persists to DB and broadcasts via Socket.IO)
      final createdMsg = await _remoteDataSource.sendMessage(
        conversationId,
        content.trim(),
        currentUserId: currentUserId,
      );

      final currentList = state.valueOrNull ?? [];
      if (!currentList.any((m) => m.id == createdMsg.id)) {
        state = AsyncValue.data([...currentList, createdMsg]);
      }

      // Also trigger refresh of conversations so lastMessage is updated
      _ref.read(conversationProvider.notifier).loadConversations();
    } catch (e) {
      // Fallback: send directly through WebSocket
      if (currentUserId != null) {
        _socket.sendChatMessage({
          'conversationId': conversationId,
          'senderId': currentUserId,
          'content': content.trim(),
          'type': 'TEXT',
        });
      }
    }
  }

  @override
  void dispose() {
    _socket.leaveConversation(conversationId);
    super.dispose();
  }
}

/// Provider family for ChatNotifier per conversation.
final chatProvider =
    StateNotifierProvider.family<ChatNotifier, AsyncValue<List<ChatMessage>>, String>(
        (ref, conversationId) {
  final remote = ref.watch(chatRemoteDataSourceProvider);
  final socket = ref.watch(socketProvider);
  final user = ref.watch(authProvider).user;
  return ChatNotifier(remote, socket, conversationId, user?.id, ref);
});

/// Deprecated alias to keep compatibility
final messagesProvider = chatProvider;
