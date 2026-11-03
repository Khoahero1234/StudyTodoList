// lib/features/study_room/providers/friends_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/friend_model.dart';
import '../data/friend_remote_datasource.dart';

class FriendsState {
  final List<FriendModel> friends;
  final List<FriendRequestModel> requests;
  final List<UserSearchResult> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;

  const FriendsState({
    this.friends = const [],
    this.requests = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
  });

  FriendsState copyWith({
    List<FriendModel>? friends,
    List<FriendRequestModel>? requests,
    List<UserSearchResult>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
  }) {
    return FriendsState(
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  final FriendRemoteDataSource _remoteDataSource;

  FriendsNotifier(this._remoteDataSource) : super(const FriendsState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final friends = await _remoteDataSource.getFriends();
      final requests = await _remoteDataSource.getIncomingRequests();
      state = state.copyWith(
        friends: friends,
        requests: requests,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true, errorMessage: null);
    try {
      final results = await _remoteDataSource.searchUsers(query.trim());
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, errorMessage: e.toString());
    }
  }

  Future<void> sendRequest(String receiverId) async {
    try {
      await _remoteDataSource.sendFriendRequest(receiverId);
      // Update local search results if present
      final updatedSearch = state.searchResults.map((u) {
        if (u.id == receiverId) {
          return UserSearchResult(
            id: u.id,
            name: u.name,
            email: u.email,
            avatarUrl: u.avatarUrl,
            isFriend: u.isFriend,
            isPendingSent: true,
            isPendingReceived: u.isPendingReceived,
          );
        }
        return u;
      }).toList();
      state = state.copyWith(searchResults: updatedSearch);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _remoteDataSource.acceptFriendRequest(requestId);
      await loadAll();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _remoteDataSource.rejectFriendRequest(requestId);
      await loadAll();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await _remoteDataSource.removeFriend(friendId);
      await loadAll();
    } catch (e) {
      rethrow;
    }
  }
}

final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final remote = ref.watch(friendRemoteDataSourceProvider);
  return FriendsNotifier(remote);
});

