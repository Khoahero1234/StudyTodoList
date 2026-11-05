// lib/features/study_room/screens/study_room_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/chat_conversation.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/models/friend_model.dart';
import '../../../core/models/study_room_model.dart';
import '../../../core/socket/socket_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/friends_provider.dart';
import '../providers/study_room_provider.dart';

class StudyRoomScreen extends ConsumerStatefulWidget {
  const StudyRoomScreen({super.key});

  @override
  ConsumerState<StudyRoomScreen> createState() => _StudyRoomScreenState();
}

class _StudyRoomScreenState extends ConsumerState<StudyRoomScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0; // 0=Chats, 1=Study Rooms, 2=Friends
  String? _selectedConversationId;
  StudyRoomModel? _activeStudyRoom;

  // Video Call & Study Room states
  bool _isMicOn = true;
  bool _isCameraOn = true;
  bool _isHandRaised = false;
  bool _isScreenSharing = false;
  bool _isRoomChatOpen = false;
  int _pomodoroSeconds = 25 * 60;
  bool _isTimerRunning = false;
  Timer? _pomodoroTimer;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _roomMsgController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _roomChatScrollController = ScrollController();
  final List<Map<String, dynamic>> _roomMessages = [];

  int _friendsSubTab = 0; // 0=Friends, 1=Requests

  @override
  void initState() {
    super.initState();
    // Setup socket listener for study room chat and media
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socket = ref.read(socketProvider);
      socket.onStudyRoomMessage((data) {
        if (mounted && data is Map<String, dynamic>) {
          setState(() {
            _roomMessages.add(data);
          });
          _scrollRoomChatToBottom();
        }
      });
    });
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _searchController.dispose();
    _messageController.dispose();
    _roomMsgController.dispose();
    _chatScrollController.dispose();
    _roomChatScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollRoomChatToBottom() {
    if (_roomChatScrollController.hasClients) {
      _roomChatScrollController.animateTo(
        _roomChatScrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If inside an active study room, show the FULL-SCREEN video workspace!
    if (_activeStudyRoom != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F111D),
        body: SafeArea(
          child: _buildActiveStudyRoomView(),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── WIDE LAYOUT (TABLET / DESKTOP) ─────────────────────────
  // ════════════════════════════════════════════════════════════
  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildSidebar(),
        SizedBox(
          width: 360,
          child: _buildMainListPanel(),
        ),
        Container(width: 1, color: AppColors.borderDark),
        Expanded(
          child: _buildDetailPanel(),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    final friendsState = ref.watch(friendsProvider);
    final pendingCount = friendsState.requests.length;

    return Container(
      width: 84,
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(right: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
            tooltip: 'Quay lại',
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 12),
          _buildSidebarItem(
            icon: Icons.chat_bubble_rounded,
            label: 'Đoạn chat',
            index: 0,
          ),
          _buildSidebarItem(
            icon: Icons.groups_rounded,
            label: 'Phòng học',
            index: 1,
          ),
          _buildSidebarItem(
            icon: Icons.people_alt_rounded,
            label: 'Bạn bè',
            badge: pendingCount,
            index: 2,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAvatar(
              ref.watch(authProvider).user?.username.isNotEmpty == true
                  ? ref.watch(authProvider).user!.username[0].toUpperCase()
                  : 'U',
              38,
              isOnline: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int index,
    int badge = 0,
  }) {
    final isActive = _tabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _tabIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      color: isActive ? AppColors.primaryLight : AppColors.textMuted,
                      size: 26,
                    ),
                    if (badge > 0)
                      Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
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
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.primaryLight : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── MOBILE LAYOUT ──────────────────────────────────────────
  // ════════════════════════════════════════════════════════════
  Widget _buildMobileLayout() {
    // If inside a chat or study room, show full screen view
    if (_selectedConversationId != null) {
      return _buildChatDetail();
    }
    if (_activeStudyRoom != null) {
      return _buildActiveStudyRoomView();
    }

    return Column(
      children: [
        _buildMobileHeader(),
        _buildMobileNavTabs(),
        Expanded(child: _buildMainListPanel()),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      color: AppColors.surfaceDark,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Text(
            _tabIndex == 0
                ? 'Đoạn chat'
                : (_tabIndex == 1 ? 'Study Rooms' : 'Bạn bè & Lời mời'),
            style: AppTextStyles.headlineSmall,
          ),
          const Spacer(),
          if (_tabIndex == 0)
            _buildActionIconButton(
              icon: Icons.add_comment_rounded,
              tooltip: 'Tạo đoạn chat',
              onTap: _showCreateChatDialog,
            )
          else if (_tabIndex == 1) ...[
            _buildActionIconButton(
              icon: Icons.vpn_key_rounded,
              tooltip: 'Nhập mã mời',
              onTap: _showJoinByCodeDialog,
            ),
            const SizedBox(width: 8),
            _buildActionIconButton(
              icon: Icons.add_rounded,
              tooltip: 'Tạo phòng học',
              onTap: _showCreateRoomDialog,
            ),
          ] else if (_tabIndex == 2)
            _buildActionIconButton(
              icon: Icons.person_add_alt_1_rounded,
              tooltip: 'Thêm bạn mới',
              onTap: _showSearchFriendsDialog,
            ),
        ],
      ),
    );
  }

  Widget _buildMobileNavTabs() {
    final friendsState = ref.watch(friendsProvider);
    final pendingCount = friendsState.requests.length;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: Row(
        children: [
          _buildMobileTabItem(label: '💬 Chat', index: 0),
          _buildMobileTabItem(label: '🏫 Phòng học', index: 1),
          _buildMobileTabItem(label: '👥 Bạn bè', index: 2, badge: pendingCount),
        ],
      ),
    );
  }

  Widget _buildMobileTabItem({
    required String label,
    required int index,
    int badge = 0,
  }) {
    final isActive = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? AppColors.primaryLight : AppColors.textMuted,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── MAIN LIST PANEL (BASED ON SELECTED TAB) ───────────────
  // ════════════════════════════════════════════════════════════
  Widget _buildMainListPanel() {
    switch (_tabIndex) {
      case 0:
        return _buildConversationList();
      case 1:
        return _buildStudyRoomsList();
      case 2:
        return _buildFriendsPanel();
      default:
        return _buildConversationList();
    }
  }

  Widget _buildDetailPanel() {
    if (_activeStudyRoom != null) {
      return _buildActiveStudyRoomView();
    }
    if (_selectedConversationId != null) {
      return _buildChatDetail();
    }
    return _buildEmptyDetailState();
  }

  // ════════════════════════════════════════════════════════════
  // ─── TAB 0: CONVERSATIONS (CHAT) ────────────────────────────
  // ════════════════════════════════════════════════════════════
  Widget _buildConversationList() {
    final asyncConvs = ref.watch(conversationProvider);

    return Container(
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cuộc trò chuyện...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderDark),
                ),
              ),
            ),
          ),
          Expanded(
            child: asyncConvs.when(
              data: (convs) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? convs
                    : convs.where((c) => c.name.toLowerCase().contains(query)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có đoạn chat nào',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showCreateChatDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Bắt đầu chat'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(conversationProvider.notifier).loadConversations(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final conv = filtered[index];
                      return _buildConversationTile(conv);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 36),
                    const SizedBox(height: 8),
                    Text('Lỗi tải cuộc trò chuyện', style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => ref.read(conversationProvider.notifier).loadConversations(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation conv) {
    final isSelected = _selectedConversationId == conv.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedConversationId = conv.id;
          _activeStudyRoom = null;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primary.withOpacity(0.4)) : null,
        ),
        child: Row(
          children: [
            _buildAvatar(
              conv.name.isNotEmpty ? conv.name[0].toUpperCase() : 'C',
              44,
              isOnline: conv.isOnline,
              isGroup: conv.isGroup,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.name,
                          style: TextStyle(
                            fontWeight: conv.isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.timeAgo.isNotEmpty)
                        Text(
                          conv.timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: conv.isUnread ? AppColors.primaryLight : AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: conv.isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: conv.isUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.isUnread && conv.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── CHAT DETAIL (REAL-TIME WEBSOCKET) ───────────────────────
  // ════════════════════════════════════════════════════════════
  Widget _buildChatDetail() {
    final conversations = ref.watch(conversationProvider).valueOrNull ?? [];
    final conv = conversations.firstWhere(
      (c) => c.id == _selectedConversationId,
      orElse: () => ChatConversation(
        id: _selectedConversationId ?? '',
        name: 'Cuộc trò chuyện',
        avatarUrl: '',
        lastMessage: '',
        timeAgo: '',
      ),
    );

    final messagesAsync = ref.watch(chatProvider(_selectedConversationId!));

    return Container(
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(bottom: BorderSide(color: AppColors.borderDark, width: 1)),
            ),
            child: Row(
              children: [
                if (MediaQuery.of(context).size.width <= 800)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () => setState(() => _selectedConversationId = null),
                  ),
                _buildAvatar(
                  conv.name.isNotEmpty ? conv.name[0].toUpperCase() : 'C',
                  40,
                  isOnline: conv.isOnline,
                  isGroup: conv.isGroup,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        conv.isGroup
                            ? '${conv.members.length} thành viên'
                            : (conv.isOnline ? 'Đang hoạt động' : 'Ngoại tuyến'),
                        style: TextStyle(
                          fontSize: 11,
                          color: conv.isOnline ? AppColors.success : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  tooltip: 'Tải lại tin nhắn',
                  onPressed: () => ref.refresh(chatProvider(_selectedConversationId!)),
                ),
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có tin nhắn nào. Hãy gửi lời chào! 👋',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Lỗi tải tin nhắn: $e', style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : 'U', 30),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      msg.senderName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.primaryGradient : null,
                    color: isMe ? null : AppColors.surfaceDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.borderDark),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    _formatTime(msg.timestamp),
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: TextField(
                controller: _messageController,
                style: AppTextStyles.bodyMedium,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && _selectedConversationId != null) {
      ref.read(chatProvider(_selectedConversationId!).notifier).send(text);
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── TAB 1: STUDY ROOMS ─────────────────────────────────────
  // ════════════════════════════════════════════════════════════
  Widget _buildStudyRoomsList() {
    final roomsAsync = ref.watch(studyRoomProvider);

    return Container(
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          // Action banner
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.surfaceDark.withOpacity(0.6),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Tạo phòng', style: TextStyle(fontSize: 12)),
                    onPressed: _showCreateRoomDialog,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.vpn_key_rounded, size: 18),
                    label: const Text('Nhập mã', style: TextStyle(fontSize: 12)),
                    onPressed: _showJoinByCodeDialog,
                  ),
                ),
              ],
            ),
          ),
          // Rooms List
          Expanded(
            child: roomsAsync.when(
              data: (rooms) {
                if (rooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có phòng học nào hoạt động',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _showCreateRoomDialog,
                          child: const Text('Tạo phòng học đầu tiên'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(studyRoomProvider.notifier).loadRooms(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return _buildStudyRoomCard(room);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 36),
                    const SizedBox(height: 8),
                    Text('Lỗi tải phòng học: $e', style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () => ref.read(studyRoomProvider.notifier).loadRooms(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyRoomCard(StudyRoomModel room) {
    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: room.isJoined ? AppColors.primary.withOpacity(0.5) : AppColors.borderDark,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _enterStudyRoom(room),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: room.isPrivate
                          ? AppColors.warning.withOpacity(0.2)
                          : AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      room.isPrivate ? 'Riêng tư' : 'Công khai',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: room.isPrivate ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              if (room.description?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  room.description!,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    room.ownerName,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.group_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${room.memberCount}/${room.maxParticipants}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  // Invite code chip
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: room.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã sao chép mã mời: ${room.inviteCode}')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mã: ${room.inviteCode}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 12, color: AppColors.secondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: room.isJoined ? AppColors.primaryLight : AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () => _enterStudyRoom(room),
                  child: Text(
                    room.isJoined ? 'Vào phòng học ngay' : 'Tham gia phòng học',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── ACTIVE STUDY ROOM VIEW (VIDEO CALL WORKSPACE) ───────────
  // ════════════════════════════════════════════════════════════
  void _enterStudyRoom(StudyRoomModel room) {
    // 1. Chuyển sang giao diện Video Call ngay lập tức (Zero freeze / lag)
    setState(() {
      _activeStudyRoom = room;
      _selectedConversationId = null;
      _roomMessages.clear();
      _isMicOn = true;
      _isCameraOn = true;
      _isHandRaised = false;
      _isScreenSharing = false;
      _isRoomChatOpen = false;
    });

    _startRoomTimer();

    // 2. Kết nối Socket.IO real-time
    try {
      final socket = ref.read(socketProvider);
      final user = ref.read(authProvider).user;
      socket.joinStudyRoom(room.id, {
        'id': user?.id,
        'name': user?.username ?? 'Thành viên',
      });
    } catch (e) {
      debugPrint('Lỗi socket khi vào phòng: $e');
    }

    // 3. Đồng bộ với Backend API ngầm (không chặn UI)
    if (!room.isJoined) {
      ref.read(studyRoomProvider.notifier).joinRoom(room.id).then((updatedRoom) {
        if (mounted && updatedRoom != null && _activeStudyRoom?.id == room.id) {
          setState(() {
            _activeStudyRoom = updatedRoom;
          });
        }
      }).catchError((e) {
        debugPrint('Async joinRoom error: $e');
      });
    }
  }

  void _startRoomTimer() {
    _pomodoroTimer?.cancel();
    _pomodoroSeconds = 25 * 60;
    _isTimerRunning = true;
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_pomodoroSeconds > 0 && _isTimerRunning) {
        setState(() => _pomodoroSeconds--);
      }
    });
  }

  void _leaveStudyRoom() async {
    if (_activeStudyRoom == null) return;
    _pomodoroTimer?.cancel();
    final roomId = _activeStudyRoom!.id;
    final user = ref.read(authProvider).user;
    await ref.read(studyRoomProvider.notifier).leaveRoom(roomId);
    ref.read(socketProvider).leaveStudyRoom(roomId, user?.id);
    if (mounted) {
      setState(() {
        _activeStudyRoom = null;
        _isRoomChatOpen = false;
        _isScreenSharing = false;
      });
    }
  }

  Widget _buildActiveStudyRoomView() {
    final room = _activeStudyRoom!;
    final user = ref.watch(authProvider).user;
    final isWide = MediaQuery.of(context).size.width > 900;

    return Container(
      color: const Color(0xFF0F111D),
      child: Column(
        children: [
          // ── Video Conference Top Bar ──
          _buildVideoCallTopBar(room),

          // ── Video Grid & In-Room Chat Area ──
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: _isScreenSharing
                            ? _buildScreenSharingView(room, user)
                            : _buildVideoGrid(room, user),
                      ),
                      // Floating Video Call Controls
                      _buildVideoCallControlBar(room),
                    ],
                  ),
                ),
                // Side chat on wide desktop / tablet
                if (isWide && _isRoomChatOpen)
                  Container(
                    width: 330,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceDark,
                      border: Border(left: BorderSide(color: AppColors.borderDark, width: 1)),
                    ),
                    child: _buildInRoomChatPanel(room, user),
                  ),
              ],
            ),
          ),

          // Sliding chat drawer for mobile view
          if (!isWide && _isRoomChatOpen)
            Container(
              height: 290,
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.borderDark, width: 1)),
              ),
              child: _buildInRoomChatPanel(room, user),
            ),
        ],
      ),
    );
  }

  // ── Top Bar in Video Call ──
  Widget _buildVideoCallTopBar(StudyRoomModel room) {
    final minutes = _pomodoroSeconds ~/ 60;
    final seconds = _pomodoroSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF161928),
        border: Border(bottom: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => setState(() => _activeStudyRoom = null),
          ),
          const SizedBox(width: 4),
          // Room title & code
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        room.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: room.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã sao chép mã mời: ${room.inviteCode}')),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mã phòng: ${room.inviteCode}',
                        style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, size: 11, color: AppColors.secondary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Shared Pomodoro Focus Timer Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 6),
                Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _isTimerRunning = !_isTimerRunning);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      _isTimerRunning ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),
          // Leave room button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withOpacity(0.2),
              foregroundColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.call_end_rounded, size: 16),
            label: const Text('Rời phòng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            onPressed: _leaveStudyRoom,
          ),
        ],
      ),
    );
  }

  // ── Video Grid Layout ──
  Widget _buildVideoGrid(StudyRoomModel room, UserModel? user) {
    // Collect participants (Me + other room members)
    final otherMembers = room.members.where((m) => m.userId != user?.id).toList();
    final totalCount = 1 + otherMembers.length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 700 ? (totalCount > 2 ? 2 : 2) : (totalCount > 2 ? 2 : 1);
          if (totalCount == 1) crossAxisCount = 1;

          return GridView(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: constraints.maxWidth > 700 ? 1.45 : 1.25,
            ),
            children: [
              // 1. My Video Tile (Local User)
              _buildVideoTile(
                name: '${user?.username ?? 'Tôi'} (Bạn)',
                avatarLetter: user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : 'U',
                isCameraOn: _isCameraOn,
                isMicOn: _isMicOn,
                isHandRaised: _isHandRaised,
                isMe: true,
                statusTag: '🎯 Đang học tập trung',
              ),

              // 2. Other Members Video Tiles
              ...otherMembers.map((m) {
                return _buildVideoTile(
                  name: m.name,
                  avatarLetter: m.name.isNotEmpty ? m.name[0].toUpperCase() : 'M',
                  isCameraOn: true,
                  isMicOn: false,
                  isHandRaised: false,
                  isMe: false,
                  statusTag: '📚 Đang làm bài tập',
                );
              }),

              // 3. If alone, show Invite Study Buddy Tile
              if (otherMembers.isEmpty)
                _buildInviteBuddyTile(room),
            ],
          );
        },
      ),
    );
  }

  // ── Single Video Tile (Call Frame) ──
  Widget _buildVideoTile({
    required String name,
    required String avatarLetter,
    required bool isCameraOn,
    required bool isMicOn,
    required bool isHandRaised,
    required bool isMe,
    required String statusTag,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe && isMicOn
              ? AppColors.primaryLight.withOpacity(0.6)
              : AppColors.borderDark,
          width: isMe && isMicOn ? 1.8 : 1,
        ),
        boxShadow: isMe && isMicOn
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Video background representation
            Positioned.fill(
              child: isCameraOn
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF252A42),
                            const Color(0xFF141829),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ambient study room simulation / camera feed representation
                          Opacity(
                            opacity: 0.25,
                            child: Icon(
                              Icons.videocam_rounded,
                              size: 72,
                              color: AppColors.secondary,
                            ),
                          ),
                          Center(
                            child: _buildAvatar(avatarLetter, 64, isOnline: true),
                          ),
                          // Subtle scanlines / HD badge
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HD 720p',
                                style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: const Color(0xFF141624),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAvatar(avatarLetter, 64),
                            const SizedBox(height: 8),
                            const Text(
                              'Camera đang tắt',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Top status pill
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusTag,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Hand raised badge
            if (isHandRaised)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warning.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Text('✋', style: TextStyle(fontSize: 14)),
                ),
              ),

            // Bottom Name and Audio Status Pill
            Positioned(
              left: 10,
              bottom: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mic status icon
                        Icon(
                          isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                          color: isMicOn ? AppColors.success : AppColors.error,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Invite Study Buddy Tile (when alone) ──
  Widget _buildInviteBuddyTile(StudyRoomModel room) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161928),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, style: BorderStyle.solid),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group_add_rounded, color: AppColors.primaryLight, size: 32),
              ),
              const SizedBox(height: 10),
              const Text(
                'Chưa có bạn học nào khác',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Mời bạn bè cùng học để tăng năng suất!',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: Text('Mã: ${room.inviteCode}', style: const TextStyle(fontSize: 11)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: room.inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã sao chép mã phòng: ${room.inviteCode}')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Screen Sharing View ──
  Widget _buildScreenSharingView(StudyRoomModel room, UserModel? user) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Screen share banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.screen_share_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Đang chia sẻ màn hình học tập • Bảng thảo luận & Tài liệu chung',
                  style: TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _isScreenSharing = false),
                  child: const Text('Dừng chia sẻ', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Shared content simulation
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.primaryLight),
                      const SizedBox(height: 12),
                      const Text(
                        'TÀI LIỆU ÔN TẬP & BÀI HỌC CHUNG',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0F18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Text(
                          '// Mục tiêu học tập hôm nay:\n'
                          '1. Hoàn thành 2 phiên Pomodoro 25 phút.\n'
                          '2. Giải 5 bài tập Giải tích & Đại số.\n'
                          '3. Ôn từ vựng tiếng Anh chuyên ngành.\n'
                          '\n💡 "Chăm chỉ hôm nay, thành công ngày mai!"',
                          style: TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Floating Video Call Control Bar (Google Meet Style) ──
  Widget _buildVideoCallControlBar(StudyRoomModel room) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Microphone Toggle
            _buildControlButton(
              icon: _isMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              tooltip: _isMicOn ? 'Tắt Micro' : 'Bật Micro',
              color: _isMicOn ? AppColors.surfaceDark : AppColors.error,
              iconColor: Colors.white,
              onTap: () {
                setState(() => _isMicOn = !_isMicOn);
                ref.read(socketProvider).toggleStudyRoomMedia({
                  'roomId': room.id,
                  'userId': ref.read(authProvider).user?.id,
                  'isMicOn': _isMicOn,
                  'isCameraOn': _isCameraOn,
                });
              },
            ),
            const SizedBox(width: 10),

            // 2. Camera Toggle
            _buildControlButton(
              icon: _isCameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              tooltip: _isCameraOn ? 'Tắt Camera' : 'Bật Camera',
              color: _isCameraOn ? AppColors.surfaceDark : AppColors.error,
              iconColor: Colors.white,
              onTap: () {
                setState(() => _isCameraOn = !_isCameraOn);
                ref.read(socketProvider).toggleStudyRoomMedia({
                  'roomId': room.id,
                  'userId': ref.read(authProvider).user?.id,
                  'isMicOn': _isMicOn,
                  'isCameraOn': _isCameraOn,
                });
              },
            ),
            const SizedBox(width: 10),

            // 3. Raise Hand
            _buildControlButton(
              icon: Icons.front_hand_rounded,
              tooltip: 'Giơ tay phát biểu',
              color: _isHandRaised ? AppColors.warning : AppColors.surfaceDark,
              iconColor: _isHandRaised ? Colors.black : Colors.white,
              onTap: () {
                setState(() => _isHandRaised = !_isHandRaised);
                ref.read(socketProvider).raiseStudyRoomHand({
                  'roomId': room.id,
                  'userId': ref.read(authProvider).user?.id,
                  'isHandRaised': _isHandRaised,
                });
                if (_isHandRaised) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bạn đã giơ tay phát biểu ✋'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 10),

            // 4. Share Screen
            _buildControlButton(
              icon: Icons.screen_share_rounded,
              tooltip: 'Chia sẻ màn hình',
              color: _isScreenSharing ? AppColors.secondary : AppColors.surfaceDark,
              iconColor: _isScreenSharing ? Colors.black : Colors.white,
              onTap: () {
                setState(() => _isScreenSharing = !_isScreenSharing);
              },
            ),
            const SizedBox(width: 10),

            // 5. In-room Chat Toggle
            _buildControlButton(
              icon: Icons.chat_bubble_rounded,
              tooltip: 'Trò chuyện trong phòng',
              color: _isRoomChatOpen ? AppColors.primary : AppColors.surfaceDark,
              iconColor: Colors.white,
              badgeCount: _roomMessages.length,
              onTap: () {
                setState(() => _isRoomChatOpen = !_isRoomChatOpen);
              },
            ),
            const SizedBox(width: 14),

            // 6. Leave Call Button (Red Pill)
            InkWell(
              onTap: _leaveStudyRoom,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.call_end_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Rời phòng',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderDark.withOpacity(0.5)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── In-Room Sliding Chat Panel ──
  Widget _buildInRoomChatPanel(StudyRoomModel room, UserModel? user) {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderDark, width: 1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryLight, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tin nhắn phòng (${_roomMessages.length})',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                onPressed: () => setState(() => _isRoomChatOpen = false),
              ),
            ],
          ),
        ),

        // Message List
        Expanded(
          child: _roomMessages.isEmpty
              ? Center(
                  child: Text(
                    'Chưa có tin nhắn trong phòng.\nHãy gửi lời chào đến các bạn!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  controller: _roomChatScrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _roomMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _roomMessages[index];
                    final senderName = msg['senderName']?.toString() ?? 'Thành viên';
                    final content = msg['content']?.toString() ?? '';
                    final isMe = msg['senderId'] == user?.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 2),
                              child: Text(
                                senderName,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.primary : AppColors.cardDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              content,
                              style: const TextStyle(fontSize: 12.5, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // In-Room Message Input Bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFF141724),
            border: Border(top: BorderSide(color: AppColors.borderDark, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _roomMsgController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhắn cho mọi người...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onSubmitted: (_) => _sendRoomMessage(),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: AppColors.primaryLight, size: 18),
                onPressed: _sendRoomMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendRoomMessage() {
    final text = _roomMsgController.text.trim();
    if (text.isNotEmpty && _activeStudyRoom != null) {
      final user = ref.read(authProvider).user;
      final payload = {
        'roomId': _activeStudyRoom!.id,
        'senderId': user?.id,
        'senderName': user?.username ?? 'Tôi',
        'content': text,
      };
      ref.read(socketProvider).sendStudyRoomMessage(payload);
      _roomMsgController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollRoomChatToBottom);
    }
  }

  // ════════════════════════════════════════════════════════════
  // ─── TAB 2: FRIENDS & REQUESTS ──────────────────────────────
  // ════════════════════════════════════════════════════════════
  Widget _buildFriendsPanel() {
    final friendsState = ref.watch(friendsProvider);

    return Container(
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          // Sub-tabs: Friends vs Requests
          Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _friendsSubTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _friendsSubTab == 0 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Bạn bè (${friendsState.friends.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _friendsSubTab == 0 ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _friendsSubTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _friendsSubTab == 1 ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lời mời kết bạn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _friendsSubTab == 1 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          if (friendsState.requests.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${friendsState.requests.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sub-tab content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(friendsProvider.notifier).loadAll(),
              child: _friendsSubTab == 0
                  ? _buildFriendsList(friendsState.friends)
                  : _buildRequestsList(friendsState.requests),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(List<FriendModel> friends) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Chưa có bạn bè nào',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showSearchFriendsDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Tìm bạn ngay'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Card(
          color: AppColors.surfaceDark,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: _buildAvatar(
              friend.name.isNotEmpty ? friend.name[0].toUpperCase() : 'F',
              40,
              isOnline: friend.isOnline,
            ),
            title: Text(
              friend.name,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            subtitle: Text(
              friend.email,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chat button -> switches to conversation tab immediately!
                IconButton(
                  icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryLight, size: 20),
                  tooltip: 'Nhắn tin',
                  onPressed: () async {
                    final conv = await ref
                        .read(conversationProvider.notifier)
                        .openOrCreateDirectChat(friend.id);
                    if (conv != null && mounted) {
                      setState(() {
                        _tabIndex = 0;
                        _selectedConversationId = conv.id;
                      });
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                  color: AppColors.cardDark,
                  onSelected: (val) {
                    if (val == 'remove') {
                      ref.read(friendsProvider.notifier).removeFriend(friend.id);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Hủy kết bạn', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(List<FriendRequestModel> requests) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Không có lời mời kết bạn nào đang chờ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Card(
          color: AppColors.surfaceDark,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAvatar(
                  req.requesterName.isNotEmpty ? req.requesterName[0].toUpperCase() : 'R',
                  40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.requesterName,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      Text(
                        req.requesterEmail,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                  tooltip: 'Chấp nhận',
                  onPressed: () {
                    ref.read(friendsProvider.notifier).acceptRequest(req.id);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 28),
                  tooltip: 'Từ chối',
                  onPressed: () {
                    ref.read(friendsProvider.notifier).rejectRequest(req.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── DIALOGS: CREATE ROOM, JOIN CODE, SEARCH FRIENDS ────────
  // ════════════════════════════════════════════════════════════
  void _showCreateRoomDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int maxParticipants = 10;
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Tạo phòng học mới', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    labelText: 'Tên phòng học',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: AppTextStyles.bodyMedium,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả mục tiêu học tập (tùy chọn)',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Giới hạn thành viên: ', style: TextStyle(color: AppColors.textSecondary)),
                    DropdownButton<int>(
                      value: maxParticipants,
                      dropdownColor: AppColors.cardDark,
                      items: [5, 10, 15, 20, 30].map((v) {
                        return DropdownMenuItem<int>(
                          value: v,
                          child: Text('$v người', style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDlgState(() => maxParticipants = v);
                      },
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Phòng riêng tư', style: TextStyle(color: AppColors.textPrimary)),
                  value: isPrivate,
                  onChanged: (v) => setDlgState(() => isPrivate = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  try {
                    final newRoom = await ref.read(studyRoomProvider.notifier).createRoom(
                          name: name,
                          description: descCtrl.text.trim(),
                          maxParticipants: maxParticipants,
                          isPrivate: isPrivate,
                        );
                    if (newRoom != null) {
                      _enterStudyRoom(newRoom);
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi tạo phòng: $e')),
                    );
                  }
                }
              },
              child: const Text('Tạo ngay'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinByCodeDialog() {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Tham gia bằng mã mời', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
          decoration: const InputDecoration(
            hintText: 'VD: A1B2C3',
            hintStyle: TextStyle(color: AppColors.textMuted, letterSpacing: 2),
            labelText: 'Mã phòng (6 ký tự)',
            labelStyle: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryDark),
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  final room = await ref.read(studyRoomProvider.notifier).joinByCode(code);
                  if (room != null) {
                    _enterStudyRoom(room);
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Không thể tham gia: $e')),
                  );
                }
              }
            },
            child: const Text('Tham gia'),
          ),
        ],
      ),
    );
  }

  void _showSearchFriendsDialog() {
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final friendsState = ref.watch(friendsProvider);

          return AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            title: const Text('Tìm kiếm bạn bè', style: TextStyle(color: AppColors.textPrimary)),
            content: SizedBox(
              width: double.maxFinite,
              height: 380,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên hoặc email...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        onPressed: () {
                          ref.read(friendsProvider.notifier).search(searchCtrl.text);
                        },
                      ),
                    ),
                    onSubmitted: (val) {
                      ref.read(friendsProvider.notifier).search(val);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (friendsState.isSearching)
                    const Center(child: CircularProgressIndicator())
                  else if (friendsState.searchResults.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          searchCtrl.text.isEmpty
                              ? 'Nhập tên hoặc email để tìm kiếm'
                              : 'Không tìm thấy người dùng phù hợp',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: friendsState.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = friendsState.searchResults[index];
                          return ListTile(
                            leading: _buildAvatar(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              36,
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            ),
                            subtitle: Text(
                              user.email,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            trailing: user.isFriend
                                ? const Text('Bạn bè', style: TextStyle(color: AppColors.success, fontSize: 11))
                                : (user.isPendingSent
                                    ? const Text('Đã gửi lời mời', style: TextStyle(color: AppColors.warning, fontSize: 11))
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        ),
                                        onPressed: () async {
                                          await ref.read(friendsProvider.notifier).sendRequest(user.id);
                                          setDlgState(() {});
                                        },
                                        child: const Text('Kết bạn', style: TextStyle(fontSize: 11)),
                                      )),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateChatDialog() {
    final friendsState = ref.watch(friendsProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Chọn bạn để nhắn tin', style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: friendsState.friends.isEmpty
              ? Center(
                  child: Text(
                    'Bạn chưa có bạn bè nào. Hãy kết bạn trước nhé!',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: friendsState.friends.length,
                  itemBuilder: (context, index) {
                    final friend = friendsState.friends[index];
                    return ListTile(
                      leading: _buildAvatar(
                        friend.name.isNotEmpty ? friend.name[0].toUpperCase() : 'F',
                        36,
                        isOnline: friend.isOnline,
                      ),
                      title: Text(
                        friend.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                      subtitle: Text(
                        friend.email,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final conv = await ref
                            .read(conversationProvider.notifier)
                            .openOrCreateDirectChat(friend.id);
                        if (conv != null && mounted) {
                          setState(() {
                            _tabIndex = 0;
                            _selectedConversationId = conv.id;
                          });
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // ─── HELPER WIDGETS ─────────────────────────────────────────
  // ════════════════════════════════════════════════════════════
  Widget _buildEmptyDetailState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceDark,
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 46,
              color: AppColors.primaryLight.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa chọn cuộc trò chuyện',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn một cuộc trò chuyện hoặc phòng học từ danh sách để bắt đầu',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    String letter,
    double size, {
    bool isOnline = false,
    bool isGroup = false,
  }) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFFE91E63),
      const Color(0xFF4CAF50),
      const Color(0xFFFF5722),
      const Color(0xFF9C27B0),
    ];
    final color = colors[letter.isEmpty ? 0 : letter.codeUnitAt(0) % colors.length];

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
          ),
          child: Center(
            child: isGroup
                ? Icon(Icons.groups_rounded, size: size * 0.45, color: Colors.white)
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
                border: Border.all(color: AppColors.backgroundDark, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primaryLight, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
