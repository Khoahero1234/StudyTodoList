// lib/core/models/chat_conversation.dart

class ConversationMemberInfo {
  final String userId;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isAdmin;

  const ConversationMemberInfo({
    required this.userId,
    required this.name,
    this.email = '',
    this.avatarUrl = '',
    this.isAdmin = false,
  });

  factory ConversationMemberInfo.fromJson(Map<String, dynamic> json) {
    String name = 'Thành viên';
    String email = '';
    String avatar = '';
    if (json['user'] is Map<String, dynamic>) {
      final user = json['user'] as Map<String, dynamic>;
      name = user['name']?.toString() ?? name;
      email = user['email']?.toString() ?? email;
      avatar = user['avatarUrl']?.toString() ?? avatar;
    }
    return ConversationMemberInfo(
      userId: json['userId']?.toString() ?? '',
      name: name,
      email: email,
      avatarUrl: avatar,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }
}

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
  final List<ConversationMemberInfo> members;

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
    this.members = const [],
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final type = json['type']?.toString() ?? 'DIRECT';
    final isGroup = type == 'GROUP';

    List<ConversationMemberInfo> parsedMembers = [];
    if (json['members'] is List) {
      parsedMembers = (json['members'] as List)
          .map((m) => ConversationMemberInfo.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    // Determine display name
    String displayName = json['name']?.toString() ?? '';
    String displayAvatar = json['avatarUrl']?.toString() ?? '';

    if (!isGroup && displayName.isEmpty) {
      final otherMember = parsedMembers.firstWhere(
        (m) => currentUserId == null || m.userId != currentUserId,
        orElse: () => parsedMembers.isNotEmpty
            ? parsedMembers.first
            : const ConversationMemberInfo(userId: '', name: 'Trò chuyện'),
      );
      displayName = otherMember.name;
      if (displayAvatar.isEmpty) {
        displayAvatar = otherMember.avatarUrl;
      }
    }

    if (displayName.isEmpty) {
      displayName = isGroup ? 'Nhóm học tập' : 'Cuộc trò chuyện';
    }

    // Format time ago
    String timeAgo = '';
    final dateStr = json['lastMessageAt'] ?? json['updatedAt'] ?? json['createdAt'];
    if (dateStr != null) {
      final date = DateTime.tryParse(dateStr.toString());
      if (date != null) {
        final diff = DateTime.now().difference(date);
        if (diff.inMinutes < 1) {
          timeAgo = 'Vừa xong';
        } else if (diff.inHours < 1) {
          timeAgo = '${diff.inMinutes}p';
        } else if (diff.inDays < 1) {
          timeAgo = '${diff.inHours}h';
        } else {
          timeAgo = '${diff.inDays}d';
        }
      }
    }

    return ChatConversation(
      id: json['id']?.toString() ?? '',
      name: displayName,
      avatarUrl: displayAvatar,
      lastMessage: json['lastMessage']?.toString() ?? 'Bắt đầu cuộc trò chuyện',
      timeAgo: timeAgo,
      isUnread: json['isUnread'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      isGroup: isGroup,
      unreadCount: json['unreadCount'] as int? ?? 0,
      members: parsedMembers,
    );
  }
}
