// lib/core/socket/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_provider.dart';

/// Service to manage Socket.IO connection.
class SocketService {
  late IO.Socket _socket;
  final String? token;

  SocketService(this.token);

  void connect() {
    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': token != null ? {'token': token} : {},
    });
    _socket.connect();
    _socket.onConnect((_) => print('Socket connected'));
    _socket.onDisconnect((_) => print('Socket disconnected'));
  }

  void joinRoom(String roomId) => _socket.emit('joinRoom', roomId);
  void leaveRoom(String roomId) => _socket.emit('leaveRoom', roomId);
  void sendMessage(String roomId, Map<String, dynamic> data) =>
      _socket.emit('sendMessage', {'roomId': roomId, ...data});
  void onMessage(void Function(dynamic) handler) => _socket.on('chatMessage', handler);
}

// Provider for the socket service.
final socketProvider = Provider<SocketService>((ref) {
  final token = ref.watch(authTokenProvider).maybeWhen(data: (t) => t, orElse: () => null);
  final service = SocketService(token);
  service.connect();
  return service;
});
