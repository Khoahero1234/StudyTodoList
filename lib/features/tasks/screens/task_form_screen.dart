// lib/features/tasks/screens/task_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../models/task_model.dart';
import '../providers/task_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final String? taskId; // null = create mode
  const TaskFormScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  final _estMinutesController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _categoryId;
  List<String> _tags = [];
  List<SubTask> _subTasks = [];
  bool _isRecurring = false;
  String? _recurringPattern;

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTaskData();
      });
    }
  }

  Future<void> _loadTaskData() async {
    try {
      final existing = ref.read(taskListProvider).tasks;
      TaskModel? task = existing.where((t) => t.id == widget.taskId).firstOrNull;

      if (task == null) {
        if (kUseMock) {
          task = await ref.read(mockTaskRepositoryProvider).getTaskById(widget.taskId!);
        } else {
          task = await ref.read(taskRepositoryProvider)?.getTaskById(widget.taskId!);
        }
      }

      if (task != null && mounted) {
        setState(() {
          _titleController.text = task!.title;
          _descController.text = task.description ?? '';
          _priority = task.priority;
          _dueDate = task.dueDate;
          if (task.dueTime != null && task.dueTime!.contains(':')) {
            final parts = task.dueTime!.split(':');
            _dueTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          _categoryId = task.categoryId;
          _tags = List.from(task.tags);
          _subTasks = List.from(task.subTasks);
          _isRecurring = task.isRecurring;
          _recurringPattern = task.recurringPattern;
          _estMinutesController.text = task.estimatedMinutes > 0 ? task.estimatedMinutes.toString() : '';
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    _estMinutesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    String? dueTimeStr;
    if (_dueTime != null) {
      dueTimeStr =
          '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}';
    }

    final notifier = ref.read(taskFormProvider.notifier);
    TaskModel? result;

    if (_isEditing) {
      result = await notifier.updateTask(
        id: widget.taskId!,
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        dueTime: dueTimeStr,
        categoryId: _categoryId,
        tags: _tags,
        subTasks: _subTasks,
        estimatedMinutes:
            int.tryParse(_estMinutesController.text) ?? 0,
      );
    } else {
      result = await notifier.createTask(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        dueTime: dueTimeStr,
        categoryId: _categoryId,
        tags: _tags,
        estimatedMinutes:
            int.tryParse(_estMinutesController.text) ?? 0,
        isRecurring: _isRecurring,
        recurringPattern: _recurringPattern,
      );
    }

    if (result != null && mounted) {
      context.pop(result);
    } else if (mounted) {
      final err = ref.read(taskFormProvider).errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(taskFormProvider.notifier).reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(taskFormProvider);
    final isLoading = formState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Task' : 'New Task',
          style: AppTextStyles.titleLarge,
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _submit,
            child: Text(
              _isEditing ? 'Save' : 'Create',
              style: AppTextStyles.labelLarge.copyWith(
                color: isLoading ? AppColors.textMuted : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            AppTextField(
              label: 'Task title *',
              hint: 'What do you need to do?',
              controller: _titleController,
              textInputAction: TextInputAction.next,
              validator: (v) => Validators.required(v, 'Title'),
              prefixIcon: const Icon(Icons.edit_outlined, size: 20),
            ),
            const SizedBox(height: 16),

            // Description
            AppTextField(
              label: 'Description (optional)',
              hint: 'Add details...',
              controller: _descController,
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              prefixIcon: const Icon(Icons.notes_rounded, size: 20),
            ),
            const SizedBox(height: 20),

            // Priority selector
            _SectionLabel(label: 'Priority'),
            const SizedBox(height: 10),
            _PrioritySelector(
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 20),

            // Category selector (Fixed selection)
            _SectionLabel(label: 'Category'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('None'),
                  selected: _categoryId == null,
                  onSelected: (_) => setState(() => _categoryId = null),
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  backgroundColor: AppColors.cardDark,
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    color: _categoryId == null ? AppColors.primary : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _categoryId == null ? AppColors.primary : AppColors.borderDark,
                  ),
                ),
                ...mockCategories.map((cat) {
                  final isSelected = _categoryId == cat.id;
                  return ChoiceChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _categoryId = cat.id),
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    backgroundColor: AppColors.cardDark,
                    labelStyle: AppTextStyles.labelMedium.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.borderDark,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // Due date & time
            _SectionLabel(label: 'Due Date & Time'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_rounded,
                    label: _dueDate != null
                        ? AppDateUtils.formatDate(_dueDate!)
                        : 'Set date',
                    isSet: _dueDate != null,
                    onTap: _pickDate,
                    onClear:
                        _dueDate != null ? () => setState(() => _dueDate = null) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_rounded,
                    label: _dueTime != null
                        ? _dueTime!.format(context)
                        : 'Set time',
                    isSet: _dueTime != null,
                    onTap: _pickTime,
                    onClear: _dueTime != null
                        ? () => setState(() => _dueTime = null)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Estimated time
            AppTextField(
              label: 'Estimated time (minutes)',
              hint: '25',
              controller: _estMinutesController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.timer_outlined, size: 20),
              validator: (v) {
                if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Tags
            _SectionLabel(label: 'Tags'),
            const SizedBox(height: 10),
            _TagsInput(
              tags: _tags,
              controller: _tagController,
              onAdd: (tag) => setState(() => _tags = [..._tags, tag]),
              onRemove: (tag) =>
                  setState(() => _tags = _tags.where((t) => t != tag).toList()),
            ),
            const SizedBox(height: 20),

            // Subtasks
            _SectionLabel(label: 'Subtasks'),
            const SizedBox(height: 10),
            _SubTasksInput(
              subTasks: _subTasks,
              onAdd: (title) => setState(() => _subTasks = [
                    ..._subTasks,
                    SubTask(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      isCompleted: false,
                    )
                  ]),
              onRemove: (id) => setState(() =>
                  _subTasks = _subTasks.where((s) => s.id != id).toList()),
              onToggle: (id) => setState(() {
                _subTasks = _subTasks.map((s) {
                  if (s.id != id) return s;
                  return s.copyWith(isCompleted: !s.isCompleted);
                }).toList();
              }),
            ),
            const SizedBox(height: 20),

            // Recurring
            _SectionLabel(label: 'Recurring'),
            const SizedBox(height: 10),
            _RecurringSelector(
              isRecurring: _isRecurring,
              pattern: _recurringPattern,
              onToggle: (v) => setState(() => _isRecurring = v),
              onPatternChanged: (p) => setState(() => _recurringPattern = p),
            ),
            const SizedBox(height: 32),

            // Submit button
            AppButton(
              label: isLoading
                  ? 'Saving...'
                  : (_isEditing ? 'Save Changes' : 'Create Task'),
              isLoading: isLoading,
              onPressed: isLoading ? null : _submit,
              prefixIcon: Icon(
                _isEditing ? Icons.save_rounded : Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surfaceDark,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surfaceDark,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }
}

// ── Supporting widgets ──────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  Color _color(TaskPriority p) {
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = selected == p;
        final color = _color(p);
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: p != TaskPriority.urgent ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : AppColors.borderDark,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.flag_rounded, color: color, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    p.label,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? color : AppColors.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.isSet,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSet ? AppColors.primary.withValues(alpha: 0.5) : AppColors.borderDark,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSet ? AppColors.primary : AppColors.textMuted,
                size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSet ? AppColors.textPrimary : AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSet && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _TagsInput extends StatelessWidget {
  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  const _TagsInput({
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map((tag) => Chip(
                  label: Text('#$tag',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryLight)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  onDeleted: () => onRemove(tag),
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  deleteIconColor: AppColors.textMuted,
                  visualDensity: VisualDensity.compact,
                )),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Suggested:', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ...['dart', 'flutter', 'reading', 'meeting', 'prm393', 'study', 'workout', 'project']
                .where((t) => !tags.contains(t))
                .map(
              (sTag) => InkWell(
                onTap: () => onAdd(sTag),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Text(
                    '+ #$sTag',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Add tag and press Enter',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty && !tags.contains(v.trim())) {
                    onAdd(v.trim());
                    controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final v = controller.text.trim();
                if (v.isNotEmpty && !tags.contains(v)) {
                  onAdd(v);
                  controller.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubTasksInput extends StatefulWidget {
  final List<SubTask> subTasks;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onToggle;

  const _SubTasksInput({
    required this.subTasks,
    required this.onAdd,
    required this.onRemove,
    required this.onToggle,
  });

  @override
  State<_SubTasksInput> createState() => _SubTasksInputState();
}

class _SubTasksInputState extends State<_SubTasksInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.subTasks.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => widget.onToggle(s.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.isCompleted
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      border: Border.all(
                        color: s.isCompleted
                            ? AppColors.primary
                            : AppColors.borderDark,
                        width: 1.5,
                      ),
                    ),
                    child: s.isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.primary, size: 12)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.title,
                    style: s.isCompleted
                        ? AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            decoration: TextDecoration.lineThrough,
                          )
                        : AppTextStyles.bodySmall,
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onRemove(s.id),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: AppTextStyles.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Add subtask...',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    widget.onAdd(v.trim());
                    _controller.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                final v = _controller.text.trim();
                if (v.isNotEmpty) {
                  widget.onAdd(v);
                  _controller.clear();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecurringSelector extends StatelessWidget {
  final bool isRecurring;
  final String? pattern;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String?> onPatternChanged;

  const _RecurringSelector({
    required this.isRecurring,
    required this.pattern,
    required this.onToggle,
    required this.onPatternChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.repeat_rounded,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Text('Recurring task', style: AppTextStyles.bodyMedium),
                ],
              ),
              Switch(
                value: isRecurring,
                onChanged: onToggle,
                activeColor: AppColors.primary,
              ),
            ],
          ),
          if (isRecurring) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _PatternChip(
                  label: 'Daily',
                  selected: pattern == 'daily',
                  onTap: () => onPatternChanged('daily'),
                ),
                const SizedBox(width: 8),
                _PatternChip(
                  label: 'Weekly',
                  selected: pattern == 'weekly',
                  onTap: () => onPatternChanged('weekly'),
                ),
                const SizedBox(width: 8),
                _PatternChip(
                  label: 'Monthly',
                  selected: pattern == 'monthly',
                  onTap: () => onPatternChanged('monthly'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PatternChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PatternChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderDark,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
