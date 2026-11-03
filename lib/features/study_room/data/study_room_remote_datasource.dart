// lib/features/study_room/data/study_room_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/study_room_model.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class StudyRoomRemoteDataSource {
  final DioClient _dioClient;

  StudyRoomRemoteDataSource(this._dioClient);

  Future<List<StudyRoomModel>> getRooms({String? currentUserId}) async {
    final response = await _dioClient.get('/studyrooms');
    final data = response.data;
    List rawList = [];
    if (data is Map<String, dynamic> && data['data'] is List) {
      rawList = data['data'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList
        .map((e) => StudyRoomModel.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
  }

  Future<StudyRoomModel> getRoom(String id, {String? currentUserId}) async {
    final response = await _dioClient.get('/studyrooms/$id');
    final data = response.data;
    final Map<String, dynamic> json = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data is Map<String, dynamic> ? data : {});
    return StudyRoomModel.fromJson(json, currentUserId: currentUserId);
  }

  Future<StudyRoomModel> createRoom({
    required String name,
    String? description,
    int maxParticipants = 10,
    bool isPrivate = false,
    String? inviteCode,
    String? currentUserId,
  }) async {
    final response = await _dioClient.post(
      '/studyrooms',
      data: {
        'name': name,
        'description': description,
        'maxParticipants': maxParticipants,
        'isPrivate': isPrivate,
        if (inviteCode != null && inviteCode.isNotEmpty) 'inviteCode': inviteCode,
      },
    );
    final data = response.data;
    final Map<String, dynamic> json = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data is Map<String, dynamic> ? data : {});
    return StudyRoomModel.fromJson(json, currentUserId: currentUserId);
  }

  Future<StudyRoomModel> joinRoom(String id, {String? currentUserId}) async {
    final response = await _dioClient.post('/studyrooms/$id/join');
    final data = response.data;
    final Map<String, dynamic> json = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data is Map<String, dynamic> ? data : {});
    return StudyRoomModel.fromJson(json, currentUserId: currentUserId);
  }

  Future<StudyRoomModel> joinByCode(String code, {String? currentUserId}) async {
    final response = await _dioClient.post(
      '/studyrooms/join-by-code',
      data: {'inviteCode': code},
    );
    final data = response.data;
    final Map<String, dynamic> json = (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : (data is Map<String, dynamic> ? data : {});
    return StudyRoomModel.fromJson(json, currentUserId: currentUserId);
  }

  Future<void> leaveRoom(String id) async {
    await _dioClient.post('/studyrooms/$id/leave');
  }
}

final studyRoomRemoteDataSourceProvider = Provider<StudyRoomRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return StudyRoomRemoteDataSource(dioClient);
});

