// lib/features/study_room/screens/study_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../study_room/providers/chat_provider.dart';
import '../../../core/models/chat_message.dart';
import '../providers/conversation_provider.dart';
import '../../../core/models/chat_conversation.dart';
import '../providers/messages_provider.dart';

// ─── Data Models ───────────────────────────────────────────
// class ChatConversation {
//   final String id;
//   final String name;
//   final String avatarUrl;
//   final String lastMessage;
//   final String timeAgo;
//   final bool isUnread;
//   final bool isOnline;
//   final bool isGroup;
//   final int unreadCount;

//   const ChatConversation({
//     required this.id,
//     required this.name,
//     required this.avatarUrl,
//     required this.lastMessage,
//     required this.timeAgo,
//     this.isUnread = false,
//     this.isOnline = false,
//     this.isGroup = false,
//     this.unreadCount = 0,
//   });
// }


// ─── Mock Data ─────────────────────────────────────────────


// ─── Main Screen ───────────────────────────────────────────
class StudyRoomScreen extends ConsumerStatefulWidget {
  const StudyRoomScreen({super.key});

  @override
  ConsumerState<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends ConsumerState<StudyRoomScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedConversationId;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _fabAnimController;
  int _sidebarIndex = 0; // 0=Chats, 1=Rooms, 2=Pending, 3=Archive

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ─── Wide (Tablet) Layout ──────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Sidebar
        _buildSidebar(),
        // Conversation list
        SizedBox(
          width: 340,
          child: _buildConversationList(),
        ),
        // Divider
        Container(width: 1, color: AppColors.borderDark),
        // Chat detail or empty state
        Expanded(
          child: _selectedConversationId != null
              ? _buildChatDetail()
              : _buildEmptyState(),
        ),
      ],
    );
  }

  // ─── Mobile Layout ─────────────────────────────────────────
  Widget _buildMobileLayout() {
    if (_selectedConversationId != null) {
      return _buildChatDetail();
    }
    return Column(
      children: [
        Expanded(child: _buildConversationList()),
      ],
    );
  }

  // ─── Sidebar (wide layout only) ───────────────────────────
  Widget _buildSidebar() {
    final items = [
      _SidebarItem(
        icon: Icons.chat_bubble_rounded,
        label: 'Đoạn chat',
        badge: 4,
        isActive: _sidebarIndex == 0,
        onTap: () => setState(() => _sidebarIndex = 0),
      ),
      _SidebarItem(
        icon: Icons.groups_rounded,
        label: 'Study Rooms',
        isActive: _sidebarIndex == 1,
        onTap: () => setState(() => _sidebarIndex = 1),
      ),
      _SidebarItem(
        icon: Icons.schedule_rounded,
        label: 'Đang chờ',
        isActive: _sidebarIndex == 2,
        onTap: () => setState(() => _sidebarIndex = 2),
      ),
      _SidebarItem(
        icon: Icons.archive_rounded,
        label: 'Kho lưu trữ',
        isActive: _sidebarIndex == 3,
        onTap: () => setState(() => _sidebarIndex = 3),
      ),
    ];

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          right: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...items,
          const Spacer(),
          // User avatar at bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAvatar('U', 36, isOnline: true),
          ),
        ],
      ),
    );
  }

  // ─── Conversation List Panel ──────────────────────────────
  Widget _buildConversationList() {
    return Container(
      color: AppColors.backgroundDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Text('Đoạn chat', style: AppTextStyles.headlineSmall),
                const Spacer(),
                _buildIconButton(Icons.edit_note_rounded, () {}),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderDark, width: 1),
              ),
              child: TextField(
                controller: _searchController,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tin nhắn...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          // Conversation tiles
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final asyncConvs = ref.watch(conversationProvider);
                return asyncConvs.when(
                  data: (convs) => ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: convs.length,
                    itemBuilder: (context, index) {
                      final conv = convs[index];
                      return _buildConversationTile(conv);
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error loading conversations')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Conversation Tile ────────────────────────────────────
  Widget _buildConversationTile(ChatConversation conv) {
    final isSelected = _selectedConversationId == conv.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedConversationId = conv.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(
                conv.name[0].toUpperCase(),
                48,
                isOnline: conv.isOnline,
                isGroup: conv.isGroup,
              ),
              const SizedBox(width: 12),
              // Name + last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight:
                            conv.isUnread ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conv.lastMessage,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: conv.isUnread
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight:
                            conv.isUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Time + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    conv.timeAgo,
                    style: AppTextStyles.caption.copyWith(
                      color: conv.isUnread
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (conv.isUnread && conv.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${conv.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Chat Detail View ─────────────────────────────────────
  Widget _buildChatDetail() {
    final conversations = ref.watch(conversationProvider).maybeWhen(
      data: (list) => list,
      orElse: () => const [],
    );
    final conv = conversations.firstWhere(
      (c) => c.id == _selectedConversationId,
      orElse: () => conversations.isNotEmpty ? conversations.first : null,
    );

    return Container(
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          // ── Chat Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(
                bottom: BorderSide(color: AppColors.borderDark, width: 1),
              ),
            ),
            child: Row(
              children: [
                // Back button (mobile only)
                if (MediaQuery.of(context).size.width <= 700)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () {
                      setState(() => _selectedConversationId = null);
                    },
                  ),
                _buildAvatar(
                  conv.name[0].toUpperCase(),
                  40,
                  isOnline: conv.isOnline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.name,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conv.isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
                        style: AppTextStyles.caption.copyWith(
                          color: conv.isOnline
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildIconButton(Icons.phone_rounded, () {}),
                _buildIconButton(Icons.videocam_rounded, () {}),
                _buildIconButton(Icons.info_outline_rounded, () {}),
              ],
            ),
          ),
          // ── Messages List ──
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final messages = ref.watch(messagesProvider(_selectedConversationId!)).maybeWhen(
          data: (list) => list,
          orElse: () => const [],
        );
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),
          // ── Message Input ──
          _buildMessageInput(),
        ],
      ),
    );
  }

  // ─── Message Bubble ───────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(msg.senderName[0].toUpperCase(), 32),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      msg.senderName,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.primaryGradient : null,
                    color: isMe ? null : AppColors.surfaceDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: AppColors.borderDark, width: 1),
                  ),
                  child: Text(
                    msg.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTime(msg.timestamp),
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ─── Message Input Bar ────────────────────────────────────
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          top: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildCircleButton(Icons.add_rounded),
          const SizedBox(width: 8),
          _buildCircleButton(Icons.image_rounded),
          const SizedBox(width: 8),
          _buildCircleButton(Icons.mic_rounded),
          const SizedBox(width: 10),
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderDark, width: 1),
              ),
              child: TextField(
                controller: _messageController,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Aa',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  suffixIcon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button
          Consumer(
            builder: (context, ref, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 20),
                  color: Colors.white,
                  onPressed: () {
                    final content = _messageController.text.trim();
                    if (content.isNotEmpty && _selectedConversationId != null) {
                      ref.read(chatProvider(_selectedConversationId!).notifier).send(content);
                      _messageController.clear();
                    }
                  },
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  // ─── Empty State (no chat selected) ───────────────────────
  Widget _buildEmptyState() {
    return Container(
      color: AppColors.backgroundDark,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.secondary.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Chưa chọn đoạn chat nào',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn một cuộc trò chuyện để bắt đầu',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper: Avatar ───────────────────────────────────────
  Widget _buildAvatar(String letter, double size,
      {bool isOnline = false, bool isGroup = false}) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFFE91E63),
      const Color(0xFF4CAF50),
      const Color(0xFFFF5722),
      const Color(0xFF9C27B0),
    ];
    final color = colors[letter.codeUnitAt(0) % colors.length];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: isGroup
                ? Icon(Icons.groups_rounded,
                    size: size * 0.45, color: Colors.white)
                : Text(
                    letter,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.backgroundDark,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Helper: Icon Button ──────────────────────────────────
  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.textSecondary, size: 22),
        ),
      ),
    );
  }

  // ─── Helper: Circle Action Button ─────────────────────────
  Widget _buildCircleButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Icon(icon, color: AppColors.primary, size: 18),
    );
  }

  // ─── Helper: Format Time ──────────────────────────────────
  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Sidebar Item Widget ──────────────────────────────────
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      color:
                          isActive ? AppColors.primary : AppColors.textMuted,
                      size: 24,
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -6,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isActive ? AppColors.primary : AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
