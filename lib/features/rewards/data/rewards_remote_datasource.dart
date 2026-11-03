// lib/features/rewards/data/rewards_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/reward_model.dart';

class RewardsRemoteDataSource {
  final DioClient _dioClient;

  RewardsRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> getRewards() async {
    try {
      final response = await _dioClient.get('/rewards');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load rewards: $e');
    }
  }

  Future<void> claimReward(String rewardId) async {
    try {
      await _dioClient.post('/rewards/claim/$rewardId');
    } catch (e) {
      throw Exception('Failed to claim reward: $e');
    }
  }
}
