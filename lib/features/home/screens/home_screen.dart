// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/missions/providers/mission_provider.dart';
import '../../../features/tasks/providers/task_provider.dart';
import '../../../features/wallet/providers/wallet_provider.dart';
import '../../../models/task_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskListProvider.notifier).loadTasks();
      ref.read(missionProvider.notifier).loadMissions(silent: true);
      ref.read(walletProvider.notifier).refreshWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.backgroundDark,
            floating: true,
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppDateUtils.greetingText()} 👋',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        user?.username ?? 'User',
                        style: AppTextStyles.titleMedium,
                      ),
                    ],
                  ),
                ),
                // Notification bell
                IconButton(
                  onPressed: () => context.push(AppRoutes.pet),
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: AppColors.textSecondary),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    (user?.username ?? 'U')[0].toUpperCase(),
                    style: AppTextStyles.labelLarge
                        .copyWith(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Date
                Text(
                  AppDateUtils.formatDate(DateTime.now()),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Progress card
                _ProgressCard(user: user),
                const SizedBox(height: 16),

                // Stats row
                _StatsRow(user: user),
                const SizedBox(height: 20),

                // Automated Missions Banner Card
                _AutomatedMissionBannerCard(),
                const SizedBox(height: 20),

                // Today's Tasks header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Tasks", style: AppTextStyles.titleMedium),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.tasks),
                      child: Text(
                        'See all',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Task items
                _DemoTaskList(),
                const SizedBox(height: 20),

                // Quick actions
                Text('Quick Actions', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                _QuickActionsGrid(),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.taskNew),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  final dynamic user;
  const _ProgressCard({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTasks = ref.watch(taskListProvider).tasks;
    final todayTasks = ref.watch(todayTasksProvider);
    final tasksToCount = todayTasks.isNotEmpty ? todayTasks : allTasks;
    final totalTasks = tasksToCount.length;
    final completedTasks = tasksToCount.where((t) => t.isCompleted).length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Progress",
                style: AppTextStyles.titleSmall.copyWith(color: Colors.white70),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$completedTasks / $totalTasks tasks completed',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  final dynamic user;
  const _StatsRow({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletBalance = ref.watch(walletProvider).balance;
    final displayedTokens =
        walletBalance > 0 ? walletBalance : (user?.tokenBalance ?? 0);

    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF6B35),
            value: '${user?.currentStreak ?? 0}',
            label: 'Day Streak',
            gradient: AppColors.streakGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(AppRoutes.wallet),
            child: _StatChip(
              icon: Icons.monetization_on_rounded,
              iconColor: AppColors.gold,
              value: '$displayedTokens',
              label: 'Tokens',
              gradient: AppColors.premiumGradient,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            icon: user?.isPremium == true
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            iconColor: AppColors.gold,
            value: user?.isPremium == true ? 'Premium' : 'Free',
            label: 'Plan',
            gradient: AppColors.cardGradient,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Gradient gradient;

  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style:
                AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _AutomatedMissionBannerCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionState = ref.watch(missionProvider);
    final completed = missionState.completedCount;
    final total = missionState.totalCount > 0 ? missionState.totalCount : 6;

    return InkWell(
      onTap: () => context.push(AppRoutes.pet),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Nhiệm vụ Tự động',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$completed/$total Xong',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tự động theo dõi tiến độ công việc, phiên Pomodoro & nhận thưởng Token.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoTaskList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTasks = ref.watch(todayTasksProvider);
    final allTasks = ref.watch(taskListProvider).tasks;
    final tasks = todayTasks.isNotEmpty ? todayTasks : allTasks;

    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        alignment: Alignment.center,
        child: Text(
          'No tasks for today! 🎉',
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: tasks
          .take(4)
          .map((task) => _DemoTaskItem(
                task: task,
                onToggle: () async {
                  final wasDone = task.isCompleted;
                  await ref
                      .read(taskListProvider.notifier)
                      .toggleTaskCompletion(task.id);
                  await ref
                      .read(missionProvider.notifier)
                      .loadMissions(silent: true);
                  await ref.read(walletProvider.notifier).refreshWallet();
                  if (!wasDone && context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ Hoàn thành "${task.title}" (+${task.tokenReward} 🪙)! Đã lưu lịch sử Ví.',
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ))
          .toList(),
    );
  }
}

class _DemoTaskItem extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;

  const _DemoTaskItem({
    required this.task,
    required this.onToggle,
  });

  Color _priorityColor() {
    switch (task.priority.value) {
      case 'low':
        return AppColors.priorityLow;
      case 'medium':
        return AppColors.priorityMedium;
      case 'high':
        return AppColors.priorityHigh;
      case 'urgent':
        return AppColors.priorityUrgent;
      default:
        return AppColors.priorityMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: isDone ? AppColors.primary : AppColors.borderDark,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: isDone
                    ? AppTextStyles.taskTitleCompleted
                    : AppTextStyles.taskTitle,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+${task.tokenReward} 🪙',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _priorityColor(),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Icons.timer_rounded,
        'label': 'Pomodoro',
        'color': AppColors.secondary,
        'route': AppRoutes.pomodoro,
      },
      {
        'icon': Icons.auto_awesome_motion_rounded,
        'label': 'Nhiệm vụ Tự động',
        'color': AppColors.accent,
        'route': AppRoutes.pet,
      },
      {
        'icon': Icons.account_balance_wallet_rounded,
        'label': 'Wallet',
        'color': AppColors.gold,
        'route': AppRoutes.wallet,
      },
      {
        'icon': Icons.workspace_premium_rounded,
        'label': 'Premium',
        'color': AppColors.priorityUrgent,
        'route': AppRoutes.premium,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions
          .map((action) => _QuickActionCard(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: () => context.push(action['route'] as String),
              ))
          .toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
