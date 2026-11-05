// lib/features/study_room/providers/conversation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/chat_conversation.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/chat_remote_datasource.dart';

class ConversationNotifier extends StateNotifier<AsyncValue<List<ChatConversation>>> {
  final ChatRemoteDataSource _remoteDataSource;
  final String? _currentUserId;

  ConversationNotifier(this._remoteDataSource, this._currentUserId)
      : super(const AsyncValue.loading()) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    try {
      state = const AsyncValue.loading();
      final list = await _remoteDataSource.getConversations(currentUserId: _currentUserId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<ChatConversation?> openOrCreateDirectChat(String otherUserId) async {
    try {
      final existing = state.valueOrNull?.firstWhere(
        (c) => !c.isGroup && c.members.any((m) => m.userId == otherUserId),
        orElse: () => const ChatConversation(id: '', name: '', avatarUrl: '', lastMessage: '', timeAgo: ''),
      );

      if (existing != null && existing.id.isNotEmpty) {
        return existing;
      }

      final conv = await _remoteDataSource.createDirectConversation(
        otherUserId,
        currentUserId: _currentUserId,
      );
      await loadConversations();
      return conv;
    } catch (e) {
      return null;
    }
  }

  Future<ChatConversation?> createGroup(String name, List<String> memberIds) async {
    try {
      final conv = await _remoteDataSource.createGroupConversation(
        name,
        memberIds,
        currentUserId: _currentUserId,
      );
      await loadConversations();
      return conv;
    } catch (e) {
      return null;
    }
  }
}

final conversationProvider =
    StateNotifierProvider<ConversationNotifier, AsyncValue<List<ChatConversation>>>((ref) {
  final remote = ref.watch(chatRemoteDataSourceProvider);
  final user = ref.watch(authProvider).user;
  return ConversationNotifier(remote, user?.id);
});
