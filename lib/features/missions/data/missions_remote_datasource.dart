// lib/features/missions/data/missions_remote_datasource.dart
import '../../../core/network/dio_client.dart';
import '../../../models/mission_model.dart';

class MissionsRemoteDataSource {
  final DioClient _dioClient;

  MissionsRemoteDataSource(this._dioClient);

  Future<MissionDailySummary> getDailyMissions() async {
    final response = await _dioClient.get('/missions/daily');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return MissionDailySummary.fromJson(data);
  }

  Future<MissionDailySummary> trackActivity({
    required String type,
    int value = 1,
  }) async {
    final response = await _dioClient.post(
      '/missions/track',
      data: {
        'type': type,
        'value': value,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return MissionDailySummary.fromJson(data);
  }

  Future<Map<String, dynamic>> generateSampleTasks() async {
    final response = await _dioClient.post('/missions/generate-tasks');
    return response.data as Map<String, dynamic>? ?? {};
  }
}
