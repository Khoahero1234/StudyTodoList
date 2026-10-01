// lib/features/tasks/widgets/task_filter_bar.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskFilterBar extends StatelessWidget {
  final TaskFilter filter;
  final ValueChanged<TaskFilter> onFilterChanged;

  const TaskFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!filter.hasActiveFilter) return const SizedBox.shrink();

    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Clear all chip
          _FilterChipItem(
            label: 'Clear filters',
            icon: Icons.close_rounded,
            color: AppColors.error,
            onTap: () => onFilterChanged(const TaskFilter()),
          ),
          const SizedBox(width: 8),

          // Active priority
          if (filter.priority != null)
            _FilterChipItem(
              label: filter.priority!.label,
              icon: Icons.flag_rounded,
              color: _priorityColor(filter.priority!),
              onTap: () =>
                  onFilterChanged(filter.copyWith(clearPriority: true)),
            ),
          if (filter.priority != null) const SizedBox(width: 8),

          // Active status
          if (filter.status != null)
            _FilterChipItem(
              label: filter.status!.value.replaceAll('_', ' '),
              icon: Icons.radio_button_checked_rounded,
              color: AppColors.secondary,
              onTap: () => onFilterChanged(filter.copyWith(clearStatus: true)),
            ),
          if (filter.status != null) const SizedBox(width: 8),

          // Active category
          if (filter.categoryId != null)
            _FilterChipItem(
              label: 'Category',
              icon: Icons.label_rounded,
              color: AppColors.accent,
              onTap: () =>
                  onFilterChanged(filter.copyWith(clearCategory: true)),
            ),

          // Active search
          if (filter.search.isNotEmpty)
            _FilterChipItem(
              label: '"${filter.search}"',
              icon: Icons.search_rounded,
              color: AppColors.textSecondary,
              onTap: () => onFilterChanged(filter.copyWith(search: '')),
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
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
            const SizedBox(width: 4),
            Icon(Icons.close_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }
}
