// lib/core/models/chat_message.dart

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isMe;

  const ChatMessage({
    required this.id,
    this.conversationId = '',
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.content,
    required this.timestamp,
    this.isMe = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final senderId = json['senderId']?.toString() ?? '';
    
    // Extract sender name from sender relation object if available
    String senderName = 'Người dùng';
    String senderAvatar = '';
    if (json['sender'] is Map<String, dynamic>) {
      final senderObj = json['sender'] as Map<String, dynamic>;
      senderName = senderObj['name']?.toString() ?? senderName;
      senderAvatar = senderObj['avatarUrl']?.toString() ?? '';
    } else if (json['senderName'] != null) {
      senderName = json['senderName'].toString();
      senderAvatar = json['senderAvatar']?.toString() ?? '';
    }

    DateTime parsedDate = DateTime.now();
    final dateStr = json['createdAt'] ?? json['timestamp'];
    if (dateStr != null) {
      parsedDate = DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
    }

    final bool isUserMe = currentUserId != null
        ? senderId == currentUserId
        : (json['isMe'] as bool? ?? false);

    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: json['content']?.toString() ?? '',
      timestamp: parsedDate,
      isMe: isUserMe,
    );
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    DateTime? timestamp,
    bool? isMe,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'senderName': senderName,
    'senderAvatar': senderAvatar,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isMe': isMe,
  };
}
