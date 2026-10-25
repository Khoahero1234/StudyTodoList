// lib/features/calendar/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/task_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/widgets/task_card.dart';
import '../../../shared/widgets/empty_widget.dart';
import '../../../shared/widgets/loading_widget.dart';

enum CalendarViewMode { day, week, month }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.week;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasksForCurrentView();
    });
  }

  void _loadTasksForCurrentView() {
    DateTime from;
    DateTime to;

    if (_viewMode == CalendarViewMode.day) {
      from = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
      to = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
    } else if (_viewMode == CalendarViewMode.week) {
      final monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
      from = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
      to = from.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    } else {
      from = DateTime(_focusedMonth.year, _focusedMonth.month, 1, 0, 0, 0);
      to = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);
    }

    ref.read(taskListProvider.notifier).loadTasks(
      dueDateFrom: from,
      dueDateTo: to,
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _focusedMonth = DateTime(date.year, date.month);
    });
    _loadTasksForCurrentView();
  }

  void _onViewModeChanged(CalendarViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
    _loadTasksForCurrentView();
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider);
    final tasks = taskState.tasks;

    // Filter tasks corresponding to current selected date view
    final displayTasks = tasks.where((t) {
      if (t.dueDate == null) return false;
      final d = t.dueDate!;
      if (_viewMode == CalendarViewMode.day) {
        return d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day;
      } else if (_viewMode == CalendarViewMode.week) {
        return d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day;
      } else {
        return d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Calendar', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Go to Today',
            onPressed: () => _onDateSelected(DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          // View Mode Selector Segmented Control
          _buildViewModeBar(),

          // Date Navigator Header
          _buildDateHeader(),

          // Dynamic Calendar View (Day / Week / Month Strip)
          if (_viewMode == CalendarViewMode.month)
            _buildMonthGrid(tasks)
          else if (_viewMode == CalendarViewMode.week)
            _buildWeekStrip(tasks)
          else
            _buildDayHeader(),

          const SizedBox(height: 12),

          // Date Summary Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  AppDateUtils.isToday(_selectedDate)
                      ? 'Today\'s Schedule'
                      : DateFormat('EEEE, MMM d').format(_selectedDate),
                  style: AppTextStyles.titleSmall,
                ),
                const Spacer(),
                if (displayTasks.isNotEmpty)
                  Text(
                    '${displayTasks.where((t) => t.isCompleted).length}/${displayTasks.length} Done',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Tasks List for Selected Date
          Expanded(
            child: taskState.isLoading
                ? const LoadingWidget(message: 'Loading schedule...')
                : displayTasks.isEmpty
                ? EmptyWidget(
              title: 'No tasks scheduled',
              subtitle: 'Tap + to add a task for ${DateFormat('MMM d').format(_selectedDate)}',
              icon: Icons.event_available_rounded,
            )
                : RefreshIndicator(
              onRefresh: () async {
                _loadTasksForCurrentView();
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                itemCount: displayTasks.length,
                itemBuilder: (context, index) {
                  final task = displayTasks[index];
                  return TaskCard(
                    task: task,
                    showDate: false,
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
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await context.push<TaskModel>(AppRoutes.taskNew);
          if (newTask != null) {
            ref.read(taskListProvider.notifier).addTask(newTask);
            _loadTasksForCurrentView();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildViewModeBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          _ViewModeTab(
            label: 'Day',
            selected: _viewMode == CalendarViewMode.day,
            onTap: () => _onViewModeChanged(CalendarViewMode.day),
          ),
          _ViewModeTab(
            label: 'Week',
            selected: _viewMode == CalendarViewMode.week,
            onTap: () => _onViewModeChanged(CalendarViewMode.week),
          ),
          _ViewModeTab(
            label: 'Month',
            selected: _viewMode == CalendarViewMode.month,
            onTap: () => _onViewModeChanged(CalendarViewMode.month),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    String title;
    if (_viewMode == CalendarViewMode.month) {
      title = DateFormat('MMMM yyyy').format(_focusedMonth);
    } else {
      title = DateFormat('MMMM yyyy').format(_selectedDate);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                if (_viewMode == CalendarViewMode.month) {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                } else if (_viewMode == CalendarViewMode.week) {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                  _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
                } else {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
                }
              });
              _loadTasksForCurrentView();
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              setState(() {
                if (_viewMode == CalendarViewMode.month) {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                } else if (_viewMode == CalendarViewMode.week) {
                  _selectedDate = _selectedDate.add(const Duration(days: 7));
                  _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
                } else {
                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                  _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
                }
              });
              _loadTasksForCurrentView();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeekStrip(List<TaskModel> tasks) {
    final monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: weekDays.map((day) {
          final isSelected = day.year == _selectedDate.year &&
              day.month == _selectedDate.month &&
              day.day == _selectedDate.day;
          final isToday = AppDateUtils.isToday(day);

          final hasTasks = tasks.any((t) =>
          t.dueDate != null &&
              t.dueDate!.year == day.year &&
              t.dueDate!.month == day.month &&
              t.dueDate!.day == day.day);

          return Expanded(
            child: GestureDetector(
              onTap: () => _onDateSelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                        ? AppColors.primary
                        : AppColors.borderDark,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(day).substring(0, 1),
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasTasks)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthGrid(List<TaskModel> tasks) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final weekLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final totalCells = startingWeekday - 1 + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          // Day of week labels
          Row(
            children: weekLabels
                .map((l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Grid of days
          ...List.generate(totalRows, (row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (col) {
                  final dayNumber = (row * 7 + col) - (startingWeekday - 2);
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 36));
                  }

                  final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                  final isSelected = cellDate.year == _selectedDate.year &&
                      cellDate.month == _selectedDate.month &&
                      cellDate.day == _selectedDate.day;
                  final isToday = AppDateUtils.isToday(cellDate);

                  final hasTasks = tasks.any((t) =>
                  t.dueDate != null &&
                      t.dueDate!.year == cellDate.year &&
                      t.dueDate!.month == cellDate.month &&
                      t.dueDate!.day == cellDate.day);

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onDateSelected(cellDate),
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : isToday
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday && !isSelected
                              ? Border.all(color: AppColors.primary)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasTasks)
                              Container(
                                width: 3,
                                height: 3,
                                margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDayHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(_selectedDate),
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM d, yyyy').format(_selectedDate),
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          if (AppDateUtils.isToday(_selectedDate))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'TODAY',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _ViewModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
