// lib/features/tasks/screens/task_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskListProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider);
    final filter = ref.watch(taskFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref.read(taskFilterProvider.notifier).state =
                      filter.copyWith(search: val);
                  ref.read(taskListProvider.notifier).loadTasks(
                        search: val,
                        status: filter.status,
                        priority: filter.priority,
                        categoryId: filter.categoryId,
                      );
                },
              )
            : Text('Tasks', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(taskFilterProvider.notifier).state =
                      filter.copyWith(search: '');
                  ref.read(taskListProvider.notifier).loadTasks(
                        status: filter.status,
                        priority: filter.priority,
                        categoryId: filter.categoryId,
                      );
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: filter.hasActiveFilter ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          TaskFilterBar(
            filter: filter,
            onFilterChanged: (newFilter) {
              ref.read(taskFilterProvider.notifier).state = newFilter;
              ref.read(taskListProvider.notifier).loadTasks(
                    status: newFilter.status,
                    priority: newFilter.priority,
                    categoryId: newFilter.categoryId,
                    search: newFilter.search,
                  );
            },
          ),

          // Main Task List
          Expanded(
            child: taskState.isLoading && taskState.tasks.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(taskListProvider.notifier).loadTasks(
                            status: filter.status,
                            priority: filter.priority,
                            categoryId: filter.categoryId,
                            search: filter.search,
                          );
                    },
                    color: AppColors.primary,
                    child: taskState.tasks.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 100),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: const BoxDecoration(
                                        color: AppColors.surfaceDark,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.assignment_outlined,
                                        size: 48,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No tasks found',
                                      style: AppTextStyles.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      filter.hasActiveFilter
                                          ? 'Try clearing filters to see more tasks.'
                                          : 'Tap the + button to create your first task!',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: taskState.tasks.length,
                            itemBuilder: (context, index) {
                              final task = taskState.tasks[index];
                              return TaskCard(
                                task: task,
                                onToggle: () {
                                  ref
                                      .read(taskListProvider.notifier)
                                      .toggleTaskCompletion(task.id);
                                },
                                onTap: () {
                                  context.push('/tasks/${task.id}');
                                },
                                onDelete: () {
                                  ref
                                      .read(taskListProvider.notifier)
                                      .deleteTask(task.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task deleted'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.taskNew);
          ref.read(taskListProvider.notifier).loadTasks();
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final filter = ref.read(taskFilterProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Tasks', style: AppTextStyles.titleMedium),
                      TextButton(
                        onPressed: () {
                          ref.read(taskFilterProvider.notifier).state =
                              const TaskFilter();
                          ref.read(taskListProvider.notifier).loadTasks();
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Reset',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Priority', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TaskPriority.values.map((p) {
                      final isSelected = filter.priority == p;
                      return ChoiceChip(
                        label: Text(p.label),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.cardDark,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        onSelected: (selected) {
                          final newFilter = filter.copyWith(
                            priority: selected ? p : null,
                            clearPriority: !selected,
                          );
                          ref.read(taskFilterProvider.notifier).state = newFilter;
                          ref.read(taskListProvider.notifier).loadTasks(
                                priority: newFilter.priority,
                                status: newFilter.status,
                                categoryId: newFilter.categoryId,
                                search: newFilter.search,
                              );
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Status', style: AppTextStyles.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: TaskStatus.values.map((s) {
                      final isSelected = filter.status == s;
                      return ChoiceChip(
                        label: Text(s.value.replaceAll('_', ' ')),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.cardDark,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        onSelected: (selected) {
                          final newFilter = filter.copyWith(
                            status: selected ? s : null,
                            clearStatus: !selected,
                          );
                          ref.read(taskFilterProvider.notifier).state = newFilter;
                          ref.read(taskListProvider.notifier).loadTasks(
                                status: newFilter.status,
                                priority: newFilter.priority,
                                categoryId: newFilter.categoryId,
                                search: newFilter.search,
                              );
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
