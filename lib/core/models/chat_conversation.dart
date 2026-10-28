// lib/core/models/chat_conversation.dart

class ChatConversation {
  final String id;
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String timeAgo;
  final bool isUnread;
  final bool isOnline;
  final bool isGroup;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.isUnread = false,
    this.isOnline = false,
    this.isGroup = false,
    this.unreadCount = 0,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) => ChatConversation(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String? ?? '',
        lastMessage: json['lastMessage'] as String? ?? '',
        timeAgo: json['timeAgo'] as String? ?? '',
        isUnread: json['isUnread'] as bool? ?? false,
        isOnline: json['isOnline'] as bool? ?? false,
        isGroup: json['isGroup'] as bool? ?? false,
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}
