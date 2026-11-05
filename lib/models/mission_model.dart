// lib/models/mission_model.dart
import 'token_transaction_model.dart';

class MissionModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int currentProgress;
  final int targetValue;
  final String unit;
  final int tokenReward;
  final int xpReward;
  final bool isCompleted;
  final DateTime? rewardedAt;
  final int progressPercentage;
  final String? icon;

  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.currentProgress,
    required this.targetValue,
    required this.unit,
    required this.tokenReward,
    required this.xpReward,
    required this.isCompleted,
    this.rewardedAt,
    required this.progressPercentage,
    this.icon,
  });

  double get progressRatio {
    if (targetValue <= 0) return 0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    final current = (json['currentProgress'] as num?)?.toInt() ?? 0;
    final target = (json['targetValue'] as num?)?.toInt() ?? 1;
    final pct = (json['progressPercentage'] as num?)?.toInt() ??
        ((current / (target > 0 ? target : 1)) * 100).round().clamp(0, 100);

    return MissionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'DAILY',
      currentProgress: current,
      targetValue: target,
      unit: json['unit'] as String? ?? 'lần',
      tokenReward: (json['tokenReward'] as num?)?.toInt() ?? 0,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? (current >= target),
      rewardedAt: json['rewardedAt'] != null
          ? DateTime.tryParse(json['rewardedAt'].toString())
          : null,
      progressPercentage: pct,
      icon: json['icon'] as String?,
    );
  }
}

class MissionDailySummary {
  final String dateKey;
  final int tasksCompleted;
  final int pomodoroSessions;
  final int focusMinutes;
  final int tokensEarnedToday;
  final List<MissionModel> missions;
  final List<MissionModel> newlyCompleted;
  final int totalTokensAwarded;
  final int walletBalance;
  final String? activityReason;
  final List<TokenTransactionModel> recentTransactions;

  const MissionDailySummary({
    required this.dateKey,
    required this.tasksCompleted,
    required this.pomodoroSessions,
    required this.focusMinutes,
    required this.tokensEarnedToday,
    required this.missions,
    required this.newlyCompleted,
    required this.totalTokensAwarded,
    required this.walletBalance,
    this.activityReason,
    required this.recentTransactions,
  });

  factory MissionDailySummary.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    final rawMissions = json['missions'] as List<dynamic>? ?? [];
    final rawNewly = json['newlyCompleted'] as List<dynamic>? ?? [];
    final rawTxs = json['recentTransactions'] as List<dynamic>? ?? [];

    return MissionDailySummary(
      dateKey: json['dateKey'] as String? ?? '',
      tasksCompleted: (stats['tasksCompleted'] as num?)?.toInt() ?? 0,
      pomodoroSessions: (stats['pomodoroSessions'] as num?)?.toInt() ?? 0,
      focusMinutes: (stats['focusMinutes'] as num?)?.toInt() ?? 0,
      tokensEarnedToday: (stats['tokensEarnedToday'] as num?)?.toInt() ?? 0,
      missions: rawMissions
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      newlyCompleted: rawNewly
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalTokensAwarded: (json['totalTokensAwarded'] as num?)?.toInt() ??
          (json['totalTokensAwardedNow'] as num?)?.toInt() ??
          0,
      walletBalance: (json['walletBalance'] as num?)?.toInt() ?? 0,
      activityReason: json['activityReason'] as String?,
      recentTransactions: rawTxs
          .map((e) => TokenTransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
