// lib/features/rewards/screens/reward_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/reward_provider.dart';

class RewardScreen extends ConsumerWidget {
  const RewardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardState = ref.watch(rewardProvider);
    final streak = rewardState.streak;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Daily Rewards & Streak', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: rewardState.isLoading && rewardState.rewards.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(rewardProvider.notifier).fetchRewards(),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Streak Header Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF9F43)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Streak',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${streak?.currentStreak ?? 0} Days 🔥',
                                style: AppTextStyles.headlineLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Longest Streak: ${streak?.longestStreak ?? 0} Days',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Available Rewards',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (rewardState.rewards.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No rewards available at the moment.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...rewardState.rewards.map((reward) {
                      final isEligible = reward.isEligible;
                      final isClaimed = reward.isClaimed;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: !isEligible && !isClaimed ? 0.6 : 1.0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isClaimed
                                  ? Colors.green.withOpacity(0.5)
                                  : isEligible
                                      ? AppColors.primary
                                      : AppColors.borderDark,
                              width: isEligible && !isClaimed ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (isEligible ? AppColors.secondary : AppColors.textSecondary).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  reward.type == 'token' ? Icons.monetization_on_rounded : Icons.card_giftcard_rounded,
                                  color: isEligible ? AppColors.secondary : AppColors.textSecondary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reward.title,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      reward.description ?? 'Requires ${reward.requiredStreak} day streak',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Reward: +${reward.amount} ${reward.type.toUpperCase()}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              isClaimed
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                                          SizedBox(width: 4),
                                          Text(
                                            'Claimed',
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: isEligible
                                          ? () async {
                                              final success = await ref
                                                  .read(rewardProvider.notifier)
                                                  .claimReward(reward.id);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      success ? 'Reward claimed successfully!' : 'Failed to claim reward',
                                                    ),
                                                    backgroundColor: success ? Colors.green : AppColors.error,
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor: AppColors.cardDark,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      ),
                                      child: Text(
                                        'Claim',
                                        style: TextStyle(
                                          color: isEligible ? Colors.white : AppColors.textMuted,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
