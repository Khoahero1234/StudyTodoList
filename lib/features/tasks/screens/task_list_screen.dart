// lib/features/tasks/screens/task_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_bar.dart';
import '../../../shared/widgets/empty_widget.dart';
import '../../../shared/widgets/loading_widget.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskListProvider.notifier).loadTasks();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final filter = ref.read(taskFilterProvider);
      ref.read(taskListProvider.notifier).loadMore(
        status: filter.status,
        priority: filter.priority,
        categoryId: filter.categoryId,
        search: filter.search,
      );
    }
  }

  void _fetchInitialTasks() {
    final filter = ref.read(taskFilterProvider);
    _searchController.text = filter.search;
    ref.read(taskListProvider.notifier).loadTasks(
      status: filter.status,
      priority: filter.priority,
      categoryId: filter.categoryId,
      search: filter.search,
      dueDateFrom: filter.dueDateFrom,
      dueDateTo: filter.dueDateTo,
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      final current = ref.read(taskFilterProvider);
      final updated = current.copyWith(search: query.trim());
      ref.read(taskFilterProvider.notifier).state = updated;
      ref.read(taskListProvider.notifier).loadTasks(
        status: updated.status,
        priority: updated.priority,
        categoryId: updated.categoryId,
        search: updated.search,
        dueDateFrom: updated.dueDateFrom,
        dueDateTo: updated.dueDateTo,
      );
    });
  }

  void _updateFilter(TaskFilter newFilter) {
    ref.read(taskFilterProvider.notifier).state = newFilter;
    if (newFilter.search != _searchController.text) {
      _searchController.text = newFilter.search;
    }
    ref.read(taskListProvider.notifier).loadTasks(
      status: newFilter.status,
      priority: newFilter.priority,
      categoryId: newFilter.categoryId,
      search: newFilter.search,
      dueDateFrom: newFilter.dueDateFrom,
      dueDateTo: newFilter.dueDateTo,
    );
  }

  void _showFilterBottomSheet() {
    final currentFilter = ref.read(taskFilterProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        TaskPriority? tempPriority = currentFilter.priority;
        TaskStatus? tempStatus = currentFilter.status;
        String? tempCategory = currentFilter.categoryId;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Tasks', style: AppTextStyles.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark),
                  const SizedBox(height: 12),

                  // Priority filter
                  Text('Priority',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: tempPriority == null,
                        onSelected: (_) =>
                            setModalState(() => tempPriority = null),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      ...TaskPriority.values.map(
                            (p) => FilterChip(
                          label: Text(p.label),
                          selected: tempPriority == p,
                          onSelected: (sel) => setModalState(
                                  () => tempPriority = sel ? p : null),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status filter
                  Text('Status',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: tempStatus == null,
                        onSelected: (_) => setModalState(() => tempStatus = null),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      ...TaskStatus.values.map(
                            (s) => FilterChip(
                          label: Text(s.value.replaceAll('_', ' ')),
                          selected: tempStatus == s,
                          onSelected: (sel) =>
                              setModalState(() => tempStatus = sel ? s : null),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category filter
                  Text('Category',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: tempCategory == null,
                        onSelected: (_) => setModalState(() => tempCategory = null),
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      ...mockCategories.map(
                            (cat) => FilterChip(
                          label: Text(cat.name),
                          selected: tempCategory == cat.id,
                          onSelected: (sel) => setModalState(
                                  () => tempCategory = sel ? cat.id : null),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              tempPriority = null;
                              tempStatus = null;
                              tempCategory = null;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateFilter(
                              currentFilter.copyWith(
                                priority: tempPriority,
                                status: tempStatus,
                                categoryId: tempCategory,
                                clearPriority: tempPriority == null,
                                clearStatus: tempStatus == null,
                                clearCategory: tempCategory == null,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
        title: _showSearch
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textMuted),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
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
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _onSearchChanged('');
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
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final newTask = await context.push<TaskModel>(AppRoutes.taskNew);
              if (newTask != null) {
                ref.read(taskListProvider.notifier).addTask(newTask);
              }
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: _showFilterBottomSheet,
              ),
              if (filter.hasActiveFilter)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
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
          // Status Tabs
          _buildStatusTabs(filter),

          // Active filter chips
          TaskFilterBar(
            filter: filter,
            onFilterChanged: _updateFilter,
          ),

          const SizedBox(height: 8),

          // Main Task List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _fetchInitialTasks();
              },
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceDark,
              child: _buildTaskListContent(taskState),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push(AppRoutes.taskNew);
          ref.read(taskListProvider.notifier).loadTasks();
          final newTask = await context.push<TaskModel>(AppRoutes.taskNew);
          if (newTask != null) {
            ref.read(taskListProvider.notifier).addTask(newTask);
          }
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
  Widget _buildStatusTabs(TaskFilter currentFilter) {
    final statusTabs = [
      {'label': 'All', 'status': null},
      {'label': 'Pending', 'status': TaskStatus.pending},
      {'label': 'In Progress', 'status': TaskStatus.inProgress},
      {'label': 'Completed', 'status': TaskStatus.completed},
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: statusTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = statusTabs[index];
          final tabStatus = tab['status'] as TaskStatus?;
          final isSelected = currentFilter.status == tabStatus;

          return ChoiceChip(
            label: Text(tab['label'] as String),
            selected: isSelected,
            onSelected: (_) {
              _updateFilter(
                currentFilter.copyWith(
                  status: tabStatus,
                  clearStatus: tabStatus == null,
                ),
              );
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.25),
            backgroundColor: AppColors.cardDark,
            labelStyle: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.borderDark,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskListContent(TaskListState state) {
    if (state.isLoading) {
      return const LoadingWidget(message: 'Loading tasks...');
    }

    if (state.errorMessage != null && state.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load tasks', style: AppTextStyles.titleSmall),
            const SizedBox(height: 6),
            Text(state.errorMessage!, style: AppTextStyles.caption),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInitialTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.tasks.isEmpty) {
      return const EmptyWidget(
        title: 'No tasks found',
        subtitle: 'Create a new task or adjust your filters',
        icon: Icons.task_alt_rounded,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: state.tasks.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.tasks.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final task = state.tasks[index];
        return TaskCard(
          task: task,
          onToggle: () {
            ref.read(taskListProvider.notifier).toggleTaskCompletion(task.id);
            ref.read(taskListProvider.notifier).completeTask(task.id);
          },
          onTap: () async {
            await context.push('/tasks/${task.id}');
          },
          onDelete: () {
            ref.read(taskListProvider.notifier).deleteTask(task.id);
          },
        );
      },
    );
  }
}
