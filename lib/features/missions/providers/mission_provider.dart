// lib/features/missions/providers/mission_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/tasks/providers/task_provider.dart';
import '../../../features/wallet/providers/wallet_provider.dart';
import '../../../models/mission_model.dart';
import '../../../models/token_transaction_model.dart';
import '../data/missions_remote_datasource.dart';

final missionsRemoteDataSourceProvider = Provider<MissionsRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return MissionsRemoteDataSource(dioClient);
});

class MissionState {
  final List<MissionModel> missions;
  final List<MissionModel> newlyCompleted;
  final List<TokenTransactionModel> recentTransactions;
  final int tasksCompletedToday;
  final int pomodoroSessionsToday;
  final int focusMinutesToday;
  final int tokensEarnedToday;
  final bool isLoading;
  final bool isSimulating;
  final String? errorMessage;
  final String? rewardBannerMessage;

  const MissionState({
    this.missions = const [],
    this.newlyCompleted = const [],
    this.recentTransactions = const [],
    this.tasksCompletedToday = 0,
    this.pomodoroSessionsToday = 0,
    this.focusMinutesToday = 0,
    this.tokensEarnedToday = 0,
    this.isLoading = false,
    this.isSimulating = false,
    this.errorMessage,
    this.rewardBannerMessage,
  });

  int get completedCount => missions.where((m) => m.isCompleted).length;
  int get totalCount => missions.length;

  MissionState copyWith({
    List<MissionModel>? missions,
    List<MissionModel>? newlyCompleted,
    List<TokenTransactionModel>? recentTransactions,
    int? tasksCompletedToday,
    int? pomodoroSessionsToday,
    int? focusMinutesToday,
    int? tokensEarnedToday,
    bool? isLoading,
    bool? isSimulating,
    String? errorMessage,
    String? rewardBannerMessage,
    bool clearError = false,
    bool clearBanner = false,
  }) {
    return MissionState(
      missions: missions ?? this.missions,
      newlyCompleted: newlyCompleted ?? this.newlyCompleted,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      tasksCompletedToday: tasksCompletedToday ?? this.tasksCompletedToday,
      pomodoroSessionsToday: pomodoroSessionsToday ?? this.pomodoroSessionsToday,
      focusMinutesToday: focusMinutesToday ?? this.focusMinutesToday,
      tokensEarnedToday: tokensEarnedToday ?? this.tokensEarnedToday,
      isLoading: isLoading ?? this.isLoading,
      isSimulating: isSimulating ?? this.isSimulating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      rewardBannerMessage:
          clearBanner ? null : (rewardBannerMessage ?? this.rewardBannerMessage),
    );
  }
}

class MissionNotifier extends StateNotifier<MissionState> {
  final MissionsRemoteDataSource _dataSource;
  final Ref _ref;

  MissionNotifier(this._dataSource, this._ref) : super(const MissionState()) {
    loadMissions();
  }

  Future<void> loadMissions({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final summary = await _dataSource.getDailyMissions();
      String? banner;
      if (summary.newlyCompleted.isNotEmpty) {
        final titles = summary.newlyCompleted.map((m) => m.title).join(', ');
        banner =
            '🎉 Tự động hoàn thành: $titles (+${summary.totalTokensAwarded} 🪙)';
      }

      state = state.copyWith(
        missions: summary.missions,
        newlyCompleted: summary.newlyCompleted,
        recentTransactions: summary.recentTransactions,
        tasksCompletedToday: summary.tasksCompleted,
        pomodoroSessionsToday: summary.pomodoroSessions,
        focusMinutesToday: summary.focusMinutes,
        tokensEarnedToday: summary.tokensEarnedToday,
        isLoading: false,
        rewardBannerMessage: banner,
      );

      if (summary.walletBalance > 0) {
        _ref.read(authProvider.notifier).setTokenBalance(summary.walletBalance);
      }
      _ref.read(walletProvider.notifier).refreshWallet();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<MissionDailySummary?> triggerActivity({
    required String type,
    int value = 1,
  }) async {
    state = state.copyWith(isSimulating: true, clearError: true, clearBanner: true);
    try {
      final summary = await _dataSource.trackActivity(type: type, value: value);

      String bannerMessage = summary.activityReason ?? 'Đã cập nhật tiến độ!';
      if (summary.newlyCompleted.isNotEmpty) {
        final missionNames = summary.newlyCompleted.map((m) => m.title).join(', ');
        bannerMessage =
            '🎉 $bannerMessage & Hoàn thành nhiệm vụ: $missionNames (Tổng +${summary.totalTokensAwarded} 🪙)';
      } else if (summary.totalTokensAwarded > 0) {
        bannerMessage = '✅ $bannerMessage (+${summary.totalTokensAwarded} 🪙)';
      }

      state = state.copyWith(
        missions: summary.missions,
        newlyCompleted: summary.newlyCompleted,
        recentTransactions: summary.recentTransactions,
        tasksCompletedToday: summary.tasksCompleted,
        pomodoroSessionsToday: summary.pomodoroSessions,
        focusMinutesToday: summary.focusMinutes,
        tokensEarnedToday: summary.tokensEarnedToday,
        isSimulating: false,
        rewardBannerMessage: bannerMessage,
      );

      _ref.read(authProvider.notifier).setTokenBalance(summary.walletBalance);
      _ref.read(walletProvider.notifier).refreshWallet();
      _ref.read(taskListProvider.notifier).loadTasks();

      return summary;
    } catch (e) {
      state = state.copyWith(
        isSimulating: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<bool> generateSampleTasks() async {
    state = state.copyWith(isSimulating: true, clearError: true);
    try {
      await _dataSource.generateSampleTasks();
      await loadMissions(silent: true);
      await _ref.read(taskListProvider.notifier).loadTasks();
      state = state.copyWith(
        isSimulating: false,
        rewardBannerMessage: '✨ Đã khởi tạo 4 công việc học tập mới trong danh sách Tasks!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSimulating: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

final missionProvider =
    StateNotifierProvider<MissionNotifier, MissionState>((ref) {
  final dataSource = ref.watch(missionsRemoteDataSourceProvider);
  return MissionNotifier(dataSource, ref);
});
