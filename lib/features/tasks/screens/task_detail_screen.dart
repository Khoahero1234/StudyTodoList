// lib/features/tasks/screens/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/task_model.dart';
import '../providers/task_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_widget.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  TaskModel? _task;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      // Try to find in existing list first
      final existing = ref.read(taskListProvider).tasks;
      final cached = existing.where((t) => t.id == widget.taskId).firstOrNull;
      if (cached != null) {
        setState(() {
          _task = cached;
          _isLoading = false;
        });
        return;
      }
      // Fallback: fetch from API
      final task = await ref
          .read(taskRepositoryProvider)
          .getTaskById(widget.taskId);
      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleComplete() async {
    if (_task == null) return;
    final notifier = ref.read(taskListProvider.notifier);
    notifier.toggleTaskCompletion(widget.taskId);

    if (!_task!.isCompleted) {
      final updated = await ref
          .read(taskRepositoryProvider)
          .completeTask(widget.taskId);
      setState(() => _task = updated);
    } else {
      setState(() => _task = _task!.copyWith(
            status: TaskStatus.pending,
            completedAt: null,
          ));
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Delete Task', style: AppTextStyles.titleMedium),
        content: Text(
          'This will permanently delete the task.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(taskRepositoryProvider).deleteTask(widget.taskId);
      ref.read(taskListProvider.notifier).deleteTask(widget.taskId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingWidget());
    if (_error != null || _task == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(backgroundColor: AppColors.backgroundDark),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Task not found', style: AppTextStyles.titleSmall),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go back')),
            ],
          ),
        ),
      );
    }

    final task = _task!;
    final priorityColor = _priorityColor(task.priority);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: AppColors.backgroundDark,
            expandedHeight: 180,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final updated = await context
                      .push<TaskModel>('/tasks/${task.id}/edit');
                  if (updated != null) {
                    setState(() => _task = updated);
                    ref.read(taskListProvider.notifier).updateTask(updated);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                onPressed: _deleteTask,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      priorityColor.withValues(alpha: 0.3),
                      AppColors.backgroundDark,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: priorityColor.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.flag_rounded,
                                      color: priorityColor, size: 12),
                                  const SizedBox(width: 4),
                                  Text(task.priority.label,
                                      style: AppTextStyles.caption
                                          .copyWith(color: priorityColor)),
                                ],
                              ),
                            ),
                            if (task.category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _hexToColor(task.category!.color)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  task.category!.name,
                                  style: AppTextStyles.caption.copyWith(
                                    color: _hexToColor(task.category!.color),
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            _StatusBadge(status: task.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          task.title,
                          style: AppTextStyles.headlineSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Description
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  _DetailSection(
                    icon: Icons.notes_rounded,
                    title: 'Description',
                    child: Text(task.description!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Meta info
                _InfoGrid(task: task),
                const SizedBox(height: 16),

                // Subtasks
                if (task.subTasks.isNotEmpty) ...[
                  _DetailSection(
                    icon: Icons.checklist_rounded,
                    title:
                        'Subtasks (${task.subTasks.where((s) => s.isCompleted).length}/${task.subTasks.length})',
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: task.subTaskProgress,
                            backgroundColor: AppColors.borderDark,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              task.subTaskProgress == 1
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...task.subTasks.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  s.isCompleted
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: s.isCompleted
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.title,
                                    style: s.isCompleted
                                        ? AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.textMuted,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          )
                                        : AppTextStyles.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tags
                if (task.tags.isNotEmpty) ...[
                  _DetailSection(
                    icon: Icons.label_outline_rounded,
                    title: 'Tags',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: task.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '#$tag',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.primaryLight),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Rewards
                _DetailSection(
                  icon: Icons.stars_rounded,
                  title: 'Rewards',
                  child: Row(
                    children: [
                      _RewardChip(
                        label: '+${task.tokenReward} Tokens',
                        icon: Icons.monetization_on_rounded,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 12),
                      _RewardChip(
                        label: '+${task.xpReward} XP',
                        icon: Icons.bolt_rounded,
                        color: AppColors.xpColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Complete button
                AppButton(
                  label: task.isCompleted
                      ? 'Mark as Incomplete'
                      : 'Mark as Complete ✓',
                  variant: task.isCompleted
                      ? AppButtonVariant.outline
                      : AppButtonVariant.primary,
                  onPressed: _toggleComplete,
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
    }
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// ── Supporting Widgets ────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case TaskStatus.completed:
        color = AppColors.success;
        label = 'Completed';
        break;
      case TaskStatus.inProgress:
        color = AppColors.info;
        label = 'In Progress';
        break;
      case TaskStatus.cancelled:
        color = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.textMuted;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final TaskModel task;
  const _InfoGrid({required this.task});

  @override
  Widget build(BuildContext context) {
    final items = <_InfoItem>[
      if (task.dueDate != null)
        _InfoItem(
          icon: Icons.calendar_today_rounded,
          label: 'Due Date',
          value: AppDateUtils.isToday(task.dueDate!)
              ? 'Today'
              : AppDateUtils.isTomorrow(task.dueDate!)
                  ? 'Tomorrow'
                  : AppDateUtils.formatDate(task.dueDate!),
          valueColor: task.isOverdue ? AppColors.error : null,
        ),
      if (task.dueTime != null)
        _InfoItem(
          icon: Icons.access_time_rounded,
          label: 'Due Time',
          value: AppDateUtils.formatTime(task.dueTime!),
        ),
      if (task.estimatedMinutes > 0)
        _InfoItem(
          icon: Icons.timer_outlined,
          label: 'Estimated',
          value: AppDateUtils.formatDuration(task.estimatedMinutes),
        ),
      _InfoItem(
        icon: Icons.create_rounded,
        label: 'Created',
        value: AppDateUtils.formatRelative(task.createdAt),
      ),
      if (task.completedAt != null)
        _InfoItem(
          icon: Icons.check_circle_rounded,
          label: 'Completed',
          value: AppDateUtils.formatRelative(task.completedAt!),
          valueColor: AppColors.success,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(item.icon,
                        color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      '${item.label}:',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      item.value,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: item.valueColor ?? AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _RewardChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _RewardChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
