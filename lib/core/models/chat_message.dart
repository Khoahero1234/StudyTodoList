// lib/core/models/chat_message.dart
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.timestamp,
    this.isMe = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        senderAvatar: json['senderAvatar'] as String? ?? '',
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isMe: json['isMe'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isMe': isMe,
      };
}
