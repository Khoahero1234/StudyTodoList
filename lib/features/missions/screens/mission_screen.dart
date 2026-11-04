// lib/features/missions/screens/mission_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/wallet/providers/wallet_provider.dart';
import '../../../features/wallet/widgets/transaction_tile.dart';
import '../../../models/mission_model.dart';
import '../providers/mission_provider.dart';

class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({super.key});

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(missionProvider.notifier).loadMissions();
      ref.read(walletProvider.notifier).refreshWallet();
    });
  }

  Future<void> _handleTrigger(String type, {int value = 1}) async {
    final result = await ref
        .read(missionProvider.notifier)
        .triggerActivity(type: type, value: value);
    if (!mounted || result == null) return;

    final banner = ref.read(missionProvider).rewardBannerMessage;
    if (banner != null && banner.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            banner,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final missionState = ref.watch(missionProvider);
    final walletState = ref.watch(walletProvider);
    final user = ref.watch(currentUserProvider);
    final currentTokens = walletState.balance > 0
        ? walletState.balance
        : (user?.tokenBalance ?? 0);

    final completedCount = missionState.completedCount;
    final totalCount = missionState.totalCount > 0 ? missionState.totalCount : 6;
    final overallProgress =
        totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    final transactionsToShow = walletState.transactions.isNotEmpty
        ? walletState.transactions.take(8).toList()
        : missionState.recentTransactions.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text('Nhiệm vụ Tự động', style: AppTextStyles.titleLarge),
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.wallet),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(
                    '$currentTokens',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () {
              ref.read(missionProvider.notifier).loadMissions();
              ref.read(walletProvider.notifier).refreshWallet();
            },
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: missionState.isLoading && missionState.missions.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(missionProvider.notifier).loadMissions();
                await ref.read(walletProvider.notifier).refreshWallet();
              },
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // 1. Thẻ Tổng quan Tiến độ Nhiệm vụ Tự động Hôm nay
                  _buildSummaryCard(
                    completedCount: completedCount,
                    totalCount: totalCount,
                    overallProgress: overallProgress,
                    missionState: missionState,
                  ),
                  const SizedBox(height: 20),

                  // 2. Danh sách Nhiệm vụ Tự động Hàng ngày
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nhiệm vụ Tự động Hôm nay',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Tự động cộng 🪙',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hệ thống tự động ghi nhận khi bạn hoàn thành Công việc học tập hoặc hoàn thành các phiên Pomodoro thực tế.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...missionState.missions
                      .map((mission) => _MissionItemCard(mission: mission)),

                  const SizedBox(height: 24),

                  // 4. Lịch sử +Token / -Token gần đây kèm lý do chi tiết
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch sử Cộng / Trừ Token gần đây',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.wallet),
                        icon: const Icon(Icons.account_balance_wallet_outlined,
                            size: 16, color: AppColors.primary),
                        label: Text(
                          'Xem Ví',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (transactionsToShow.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Chưa có giao dịch Token nào.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ...transactionsToShow.map(
                      (tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: TransactionTile(transaction: tx),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required int completedCount,
    required int totalCount,
    required double overallProgress,
    required MissionState missionState,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiến độ Nhiệm vụ Tự động',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCount / $totalCount Hoàn thành',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${(overallProgress * 100).round()}%',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallProgress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStatItem(
                  label: 'Công việc xong',
                  value: '${missionState.tasksCompletedToday}',
                  icon: Icons.task_alt_rounded,
                ),
              ),
              Expanded(
                child: _MiniStatItem(
                  label: 'Phiên Pomodoro',
                  value: '${missionState.pomodoroSessionsToday}',
                  icon: Icons.timer_rounded,
                ),
              ),
              Expanded(
                child: _MiniStatItem(
                  label: 'Phút tập trung',
                  value: '${missionState.focusMinutesToday}p',
                  icon: Icons.bolt_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSimulationCard(bool isSimulating) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡ Bảng Test Nhanh Nhiệm Vụ Tự Động',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Bấm để mô phỏng hoạt động học tập, tự động hoàn thành task, +Token & ghi lịch sử ngay lập tức',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSimulating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SimActionButton(
                icon: Icons.check_circle_outline_rounded,
                label: '+1 Hoàn thành Task',
                color: AppColors.success,
                disabled: isSimulating,
                onTap: () => _handleTrigger('TASK_COMPLETED', value: 1),
              ),
              _SimActionButton(
                icon: Icons.timer_outlined,
                label: '+1 Pomodoro (25p)',
                color: AppColors.secondary,
                disabled: isSimulating,
                onTap: () => _handleTrigger('POMODORO_COMPLETED', value: 25),
              ),
              _SimActionButton(
                icon: Icons.bolt_rounded,
                label: '+30 Phút Tập trung',
                color: AppColors.gold,
                disabled: isSimulating,
                onTap: () => _handleTrigger('FOCUS_MINUTES', value: 30),
              ),
              _SimActionButton(
                icon: Icons.playlist_add_check_rounded,
                label: 'Tạo 4 Task mẫu',
                color: AppColors.primary,
                disabled: isSimulating,
                onTap: () async {
                  final ok = await ref
                      .read(missionProvider.notifier)
                      .generateSampleTasks();
                  if (!mounted || !ok) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '✨ Đã tạo 4 công việc học tập mới trong tab Tasks!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              _SimActionButton(
                icon: Icons.restart_alt_rounded,
                label: 'Reset tiến độ hôm nay',
                color: AppColors.textSecondary,
                disabled: isSimulating,
                onTap: () => _handleTrigger('RESET_TODAY_MISSIONS'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SimActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _SimActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionItemCard extends StatelessWidget {
  final MissionModel mission;

  const _MissionItemCard({required this.mission});

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'DAILY':
        return Icons.wb_sunny_rounded;
      case 'TASK':
        return Icons.task_alt_rounded;
      case 'POMODORO':
        return Icons.timer_rounded;
      case 'FOCUS':
        return Icons.bolt_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'DAILY':
        return AppColors.gold;
      case 'TASK':
        return AppColors.primary;
      case 'POMODORO':
        return AppColors.secondary;
      case 'FOCUS':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(mission.category);
    final isDone = mission.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? AppColors.success.withValues(alpha: 0.6)
              : AppColors.borderDark,
          width: isDone ? 1.4 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDone ? AppColors.success : color)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDone
                      ? Icons.verified_rounded
                      : _getCategoryIcon(mission.category),
                  color: isDone ? AppColors.success : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mission.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '+${mission.tokenReward} 🪙',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: mission.progressRatio,
              backgroundColor: AppColors.surfaceDark,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? AppColors.success : color,
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Tiến độ: ${mission.currentProgress} / ${mission.targetValue} ${mission.unit}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDone
                      ? '✓ Đã hoàn thành (+${mission.tokenReward} 🪙)'
                      : 'Đang theo dõi (${mission.progressPercentage}%)',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: isDone ? AppColors.success : color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
