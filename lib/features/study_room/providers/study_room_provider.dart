// lib/features/study_room/providers/study_room_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/study_room_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/study_room_remote_datasource.dart';

class StudyRoomNotifier extends StateNotifier<AsyncValue<List<StudyRoomModel>>> {
  final StudyRoomRemoteDataSource _remoteDataSource;
  final String? _currentUserId;

  StudyRoomNotifier(this._remoteDataSource, this._currentUserId)
      : super(const AsyncValue.loading()) {
    loadRooms();
  }

  Future<void> loadRooms() async {
    try {
      state = const AsyncValue.loading();
      final list = await _remoteDataSource.getRooms(currentUserId: _currentUserId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<StudyRoomModel?> createRoom({
    required String name,
    String? description,
    int maxParticipants = 10,
    bool isPrivate = false,
    String? inviteCode,
  }) async {
    try {
      final room = await _remoteDataSource.createRoom(
        name: name,
        description: description,
        maxParticipants: maxParticipants,
        isPrivate: isPrivate,
        inviteCode: inviteCode,
        currentUserId: _currentUserId,
      );
      await loadRooms();
      return room;
    } catch (e) {
      rethrow;
    }
  }

  Future<StudyRoomModel?> joinRoom(String roomId) async {
    try {
      final room = await _remoteDataSource.joinRoom(roomId, currentUserId: _currentUserId);
      await loadRooms();
      return room;
    } catch (e) {
      rethrow;
    }
  }

  Future<StudyRoomModel?> joinByCode(String code) async {
    try {
      final room = await _remoteDataSource.joinByCode(code, currentUserId: _currentUserId);
      await loadRooms();
      return room;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      await _remoteDataSource.leaveRoom(roomId);
      await loadRooms();
    } catch (e) {
      rethrow;
    }
  }
}

final studyRoomProvider =
    StateNotifierProvider<StudyRoomNotifier, AsyncValue<List<StudyRoomModel>>>((ref) {
  final remote = ref.watch(studyRoomRemoteDataSourceProvider);
  final user = ref.watch(authProvider).user;
  return StudyRoomNotifier(remote, user?.id);
});

final singleStudyRoomProvider =
    FutureProvider.family<StudyRoomModel, String>((ref, roomId) async {
  final remote = ref.watch(studyRoomRemoteDataSourceProvider);
  final user = ref.watch(authProvider).user;
  return remote.getRoom(roomId, currentUserId: user?.id);
});

