// lib/models/reward_model.dart

class LoginStreakModel {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;

  const LoginStreakModel({
    required this.currentStreak,
    required this.longestStreak,
    this.lastLoginDate,
  });

  factory LoginStreakModel.fromJson(Map<String, dynamic> json) {
    return LoginStreakModel(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.tryParse(json['lastLoginDate'] as String)
          : null,
    );
  }
}

class RewardModel {
  final String id;
  final String title;
  final String? description;
  final String type;
  final int amount;
  final int requiredStreak;
  final bool isClaimed;
  final bool isEligible;

  const RewardModel({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.amount,
    required this.requiredStreak,
    required this.isClaimed,
    required this.isEligible,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'token',
      amount: json['amount'] as int? ?? 10,
      requiredStreak: json['requiredStreak'] as int? ?? 1,
      isClaimed: json['isClaimed'] as bool? ?? false,
      isEligible: json['isEligible'] as bool? ?? false,
    );
  }
}
