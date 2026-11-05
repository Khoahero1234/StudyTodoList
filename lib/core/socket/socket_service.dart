// lib/core/socket/socket_service.dart
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_provider.dart';
import '../constants/app_constants.dart';

/// Service to manage Socket.IO connection.
class SocketService {
  IO.Socket? _socket;
  final String? token;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  SocketService(this.token);

  void connect() {
    if (_socket != null && _socket!.connected) return;

    // Extract socket URL from AppConstants.baseUrl (strip /api/v1)
    String socketUrl = AppConstants.baseUrl;
    if (socketUrl.contains('/api/v1')) {
      socketUrl = socketUrl.replaceAll('/api/v1', '');
    }

    try {
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth(token != null ? {'token': token} : {})
            .setExtraHeaders(token != null ? {'Authorization': 'Bearer $token'} : {})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('🔌 Socket connected to $socketUrl');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('🔌 Socket disconnected');
      });

      _socket!.onConnectError((err) {
        debugPrint('❌ Socket connect error: $err');
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('❌ Error initializing socket: $e');
    }
  }

  // ─── Chat Events ──────────────────────────────────────────
  void joinConversation(String conversationId) {
    _socket?.emit('chat:join', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('chat:leave', {'conversationId': conversationId});
  }

  void sendChatMessage(Map<String, dynamic> data) {
    _socket?.emit('chat:message', data);
  }

  void onChatMessage(void Function(dynamic) handler) {
    _socket?.off('chat:message');
    _socket?.on('chat:message', handler);
  }

  void offChatMessage() {
    _socket?.off('chat:message');
  }

  // ─── Study Room Events ─────────────────────────────────────
  void joinStudyRoom(String roomId, [Map<String, dynamic>? user]) {
    _socket?.emit('studyRoom:join', {'roomId': roomId, 'user': user});
  }

  void leaveStudyRoom(String roomId, [String? userId]) {
    _socket?.emit('studyRoom:leave', {'roomId': roomId, 'userId': userId});
  }

  void sendStudyRoomMessage(Map<String, dynamic> data) {
    _socket?.emit('studyRoom:message', data);
  }

  void onStudyRoomMessage(void Function(dynamic) handler) {
    _socket?.off('studyRoom:message');
    _socket?.on('studyRoom:message', handler);
  }

  void offStudyRoomMessage() {
    _socket?.off('studyRoom:message');
  }

  void onStudyRoomUserJoined(void Function(dynamic) handler) {
    _socket?.off('studyRoom:userJoined');
    _socket?.on('studyRoom:userJoined', handler);
  }

  void onStudyRoomUserLeft(void Function(dynamic) handler) {
    _socket?.off('studyRoom:userLeft');
    _socket?.on('studyRoom:userLeft', handler);
  }

  void toggleStudyRoomMedia(Map<String, dynamic> data) {
    _socket?.emit('studyRoom:toggleMedia', data);
  }

  void onStudyRoomMediaChanged(void Function(dynamic) handler) {
    _socket?.off('studyRoom:mediaChanged');
    _socket?.on('studyRoom:mediaChanged', handler);
  }

  void raiseStudyRoomHand(Map<String, dynamic> data) {
    _socket?.emit('studyRoom:raiseHand', data);
  }

  void raiseHandInStudyRoom(Map<String, dynamic> data) => raiseStudyRoomHand(data);

  void onStudyRoomHandRaised(void Function(dynamic) handler) {
    _socket?.off('studyRoom:handRaised');
    _socket?.on('studyRoom:handRaised', handler);
  }

  // ─── Backward compatibility aliases ────────────────────────
  void joinRoom(String roomId) => joinConversation(roomId);
  void leaveRoom(String roomId) => leaveConversation(roomId);
  void sendMessage(String roomId, Map<String, dynamic> data) =>
      sendChatMessage({'conversationId': roomId, ...data});
  void onMessage(void Function(dynamic) handler) => onChatMessage(handler);

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}

// Provider for the socket service.
final socketProvider = Provider<SocketService>((ref) {
  final token = ref.watch(authTokenProvider).valueOrNull;
  final service = SocketService(token);
  service.connect();
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});
