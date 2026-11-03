// lib/features/rewards/providers/reward_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/reward_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../data/rewards_remote_datasource.dart';

final rewardsRemoteDataSourceProvider = Provider<RewardsRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RewardsRemoteDataSource(dioClient);
});

class RewardState {
  final LoginStreakModel? streak;
  final List<RewardModel> rewards;
  final bool isLoading;
  final String? errorMessage;

  const RewardState({
    this.streak,
    this.rewards = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  RewardState copyWith({
    LoginStreakModel? streak,
    List<RewardModel>? rewards,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RewardState(
      streak: streak ?? this.streak,
      rewards: rewards ?? this.rewards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RewardNotifier extends StateNotifier<RewardState> {
  final RewardsRemoteDataSource _remoteDataSource;
  final Ref _ref;

  RewardNotifier(this._remoteDataSource, this._ref) : super(const RewardState()) {
    fetchRewards();
  }

  Future<void> fetchRewards() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _remoteDataSource.getRewards();
      final streakData = data['streak'] as Map<String, dynamic>?;
      final streak = streakData != null ? LoginStreakModel.fromJson(streakData) : null;

      final rawList = data['rewards'] as List<dynamic>? ?? [];
      final rewards = rawList
          .map((e) => RewardModel.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        streak: streak,
        rewards: rewards,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> claimReward(String rewardId) async {
    try {
      await _remoteDataSource.claimReward(rewardId);

      // Trigger automatic refresh on wallet balance and user details
      _ref.read(walletProvider.notifier).refreshWallet();
      _ref.read(authProvider.notifier).refreshUser();

      // Refresh rewards list to update claimed state
      await fetchRewards();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final rewardProvider = StateNotifierProvider<RewardNotifier, RewardState>((ref) {
  final remoteDataSource = ref.watch(rewardsRemoteDataSourceProvider);
  return RewardNotifier(remoteDataSource, ref);
});
