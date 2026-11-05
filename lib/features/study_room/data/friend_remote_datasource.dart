// lib/features/study_room/data/friend_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/friend_model.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class FriendRemoteDataSource {
  final DioClient _dioClient;

  FriendRemoteDataSource(this._dioClient);

  Future<List<FriendModel>> getFriends() async {
    final response = await _dioClient.get('/friends/list');
    final data = response.data;
    List rawList = [];
    if (data is Map<String, dynamic> && data['data'] is List) {
      rawList = data['data'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList
        .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FriendRequestModel>> getIncomingRequests() async {
    final response = await _dioClient.get('/friends/requests');
    final data = response.data;
    List rawList = [];
    if (data is Map<String, dynamic> && data['data'] is List) {
      rawList = data['data'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList
        .map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendFriendRequest(String receiverId) async {
    await _dioClient.post('/friends/request', data: {'receiverId': receiverId});
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _dioClient.post('/friends/accept', data: {'requestId': requestId});
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _dioClient.post('/friends/reject', data: {'requestId': requestId});
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    final response = await _dioClient.get(
      '/friends/search',
      queryParameters: {'q': query},
    );
    final data = response.data;
    List rawList = [];
    if (data is Map<String, dynamic> && data['data'] is List) {
      rawList = data['data'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList
        .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> removeFriend(String friendId) async {
    await _dioClient.delete('/friends/$friendId');
  }
}

final friendRemoteDataSourceProvider = Provider<FriendRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return FriendRemoteDataSource(dioClient);
});

