// lib/features/study_room/providers/chat_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/socket/socket_service.dart';
import '../../../core/models/chat_message.dart';

/// ChatNotifier manages a list of ChatMessage for a specific room.
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final SocketService _socket;
  final String roomId;

  ChatNotifier(this._socket, this.roomId) : super([]) {
    // Join the room and listen for incoming messages.
    _socket.joinRoom(roomId);
    _socket.onMessage(_handleIncoming);
  }

  void _handleIncoming(dynamic data) {
    // Expect data to be a JSON map matching ChatMessage fields.
    final msg = ChatMessage.fromJson(data as Map<String, dynamic>);
    state = [...state, msg];
  }

  void send(String content) {
    final msg = {
      'senderId': 'me', // TODO: replace with actual user id
      'senderName': 'Me',
      'senderAvatar': '',
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _socket.sendMessage(roomId, msg);
  }

  @override
  void dispose() {
    _socket.leaveRoom(roomId);
    super.dispose();
  }
}

/// Provider family for ChatNotifier per room.
final chatProvider = StateNotifierProvider.family<ChatNotifier, List<ChatMessage>, String>((ref, roomId) {
  final socket = ref.watch(socketProvider);
  return ChatNotifier(socket, roomId);
});
