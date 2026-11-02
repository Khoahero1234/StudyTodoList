// lib/features/tasks/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/task_model.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool showDate;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    this.onDelete,
    this.showDate = true,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _pressing = false;

  Color _priorityColor() {
    switch (widget.task.priority) {
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

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isCompleted = task.isCompleted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) => setState(() => _pressing = false),
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Dismissible(
          key: Key('task_${task.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 24),
          ),
          confirmDismiss: (_) async {
            if (widget.onDelete != null) {
              widget.onDelete!();
            }
            return false; // We handle deletion ourselves
          },
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: task.isOverdue
                      ? AppColors.error.withValues(alpha: 0.4)
                      : AppColors.borderDark,
                  width: task.isOverdue ? 1.5 : 1,
                ),
                boxShadow: _pressing
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  _buildMainRow(),
                  if (task.subTasks.isNotEmpty) _buildSubtaskProgress(),
                  if (task.tags.isNotEmpty) _buildTags(),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildMainRow() {
    final task = widget.task;
    final isCompleted = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator bar
          Container(
            width: 3,
            height: 48,
            decoration: BoxDecoration(
              color: _priorityColor(),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Checkbox
          GestureDetector(
            onTap: widget.onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? AppColors.primary : AppColors.borderDark,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: isCompleted
                      ? AppTextStyles.taskTitleCompleted
                      : AppTextStyles.taskTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                _buildMetaRow(),
              ],
            ),
          ),

          // Category dot + chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (task.category != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _hexToColor(task.category!.color)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.category!.name,
                    style: AppTextStyles.caption.copyWith(
                      color: _hexToColor(task.category!.color),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    final task = widget.task;
    final items = <Widget>[];

    // Due date
    if (task.dueDate != null && widget.showDate) {
      final isOverdue = task.isOverdue;
      final label = AppDateUtils.isToday(task.dueDate!)
          ? 'Today'
          : AppDateUtils.isTomorrow(task.dueDate!)
              ? 'Tomorrow'
              : AppDateUtils.formatShortDate(task.dueDate!);
      items.add(
        _MetaChip(
          icon: Icons.calendar_today_rounded,
          label: label,
          color: isOverdue ? AppColors.error : AppColors.textSecondary,
        ),
      );
    }

    // Estimated time
    if (task.estimatedMinutes > 0) {
      items.add(
        _MetaChip(
          icon: Icons.timer_outlined,
          label: AppDateUtils.formatDuration(task.estimatedMinutes),
          color: AppColors.textMuted,
        ),
      );
    }

    // Subtask count
    if (task.subTasks.isNotEmpty) {
      final done = task.subTasks.where((s) => s.isCompleted).length;
      items.add(
        _MetaChip(
          icon: Icons.checklist_rounded,
          label: '$done/${task.subTasks.length}',
          color: AppColors.textMuted,
        ),
      );
    }

    // Token reward
    items.add(
      _MetaChip(
        icon: Icons.monetization_on_outlined,
        label: '+${task.tokenReward}',
        color: AppColors.gold,
      ),
    );

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: items,
    );
  }

  Widget _buildSubtaskProgress() {
    final task = widget.task;
    final progress = task.subTaskProgress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.borderDark, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.borderDark,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1 ? AppColors.success : AppColors.primary,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(
                  color: progress == 1 ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Wrap(
        spacing: 6,
        children: widget.task.tags
            .take(3)
            .map(
              (tag) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$tag',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption.copyWith(color: color)),
      ],
    );
  }
}
