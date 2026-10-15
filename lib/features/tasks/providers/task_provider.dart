// lib/features/tasks/providers/task_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/mock/mock_task_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/task_model.dart';
import '../data/task_remote_datasource.dart';
import '../data/task_repository.dart';

// ─── Infrastructure ──────────────────────────────────────────
final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return TaskRemoteDataSource(dioClient);
});

final taskRepositoryProvider = Provider<TaskRepository?>((ref) {
  if (kUseMock) return null; // Không dùng khi mock mode
  final remote = ref.watch(taskRemoteDataSourceProvider);
  return TaskRepository(remote);
});

/// Mock repository dùng chung (singleton theo provider scope)
final mockTaskRepositoryProvider = Provider<MockTaskRepository>((ref) {
  return MockTaskRepository();
});

// ─── Filter State ────────────────────────────────────────────
class TaskFilter {
  final TaskStatus? status;
  final TaskPriority? priority;
  final String? categoryId;
  final String search;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;

  const TaskFilter({
    this.status,
    this.priority,
    this.categoryId,
    this.search = '',
    this.dueDateFrom,
    this.dueDateTo,
  });

  TaskFilter copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    String? search,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearCategory = false,
  }) {
    return TaskFilter(
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
      dueDateFrom: dueDateFrom ?? this.dueDateFrom,
      dueDateTo: dueDateTo ?? this.dueDateTo,
    );
  }

  bool get hasActiveFilter =>
      status != null ||
      priority != null ||
      categoryId != null ||
      search.isNotEmpty;
}

final taskFilterProvider = StateProvider<TaskFilter>((ref) => const TaskFilter());

// ─── Task List State ─────────────────────────────────────────
class TaskListState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final bool hasMore;

  const TaskListState({
    this.tasks = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.hasMore = false,
  });

  TaskListState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    bool? hasMore,
    bool clearError = false,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository? _repository;
  final MockTaskRepository? _mockRepo;

  TaskListNotifier({TaskRepository? repository, MockTaskRepository? mockRepo})
      : _repository = repository,
        _mockRepo = mockRepo,
        super(const TaskListState());

  Future<PaginatedTasks> _fetch({
    required int page,
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    String? search,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) {
    if (kUseMock) {
      return _mockRepo!.getTasks(
        page: page,
        status: status,
        priority: priority,
        categoryId: categoryId,
        search: search,
        dueDateFrom: dueDateFrom,
        dueDateTo: dueDateTo,
      );
    }
    return _repository!.getTasks(
      page: page,
      status: status,
      priority: priority,
      categoryId: categoryId,
      search: search,
      dueDateFrom: dueDateFrom,
      dueDateTo: dueDateTo,
    );
  }

  Future<void> loadTasks({
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    String? search,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _fetch(
        page: 1,
        status: status,
        priority: priority,
        categoryId: categoryId,
        search: search,
        dueDateFrom: dueDateFrom,
        dueDateTo: dueDateTo,
      );
      state = state.copyWith(
        tasks: result.tasks,
        isLoading: false,
        currentPage: 1,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore({
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    String? search,
  }) async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _fetch(
        page: state.currentPage + 1,
        status: status,
        priority: priority,
        categoryId: categoryId,
        search: search,
      );
      state = state.copyWith(
        tasks: [...state.tasks, ...result.tasks],
        isLoadingMore: false,
        currentPage: state.currentPage + 1,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> completeTask(String id) async {
    try {
      final updated = kUseMock
          ? await _mockRepo!.completeTask(id)
          : await _repository!.completeTask(id);
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == id ? updated : t).toList(),
      );
    } catch (e) {
      // Ignore API failure
    }
  }

  Future<void> deleteTask(String id) async {
    // Optimistic update
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != id).toList(),
    );
    try {
      if (kUseMock) {
        await _mockRepo!.deleteTask(id);
      } else {
        await _repository!.deleteTask(id);
      }
    } catch (_) {
      // Đã xóa optimistically — bỏ qua lỗi
    }
  }

  void addTask(TaskModel task) {
    state = state.copyWith(tasks: [task, ...state.tasks]);
  }

  void updateTask(TaskModel updated) {
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.id == updated.id ? updated : t).toList(),
    );
  }

  void toggleTaskCompletion(String id) {
    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.id != id) return t;
        final newStatus =
            t.isCompleted ? TaskStatus.pending : TaskStatus.completed;
        return t.copyWith(
          status: newStatus,
          completedAt:
              newStatus == TaskStatus.completed ? DateTime.now() : null,
        );
      }).toList(),
    );
  }
}

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  if (kUseMock) {
    return TaskListNotifier(mockRepo: ref.watch(mockTaskRepositoryProvider));
  }
  final repository = ref.watch(taskRepositoryProvider);
  return TaskListNotifier(repository: repository);
});

final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(taskListProvider).tasks;
  final now = DateTime.now();
  return tasks.where((t) {
    if (t.dueDate == null) return false;
    final d = t.dueDate!;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }).toList();
});

class TaskFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const TaskFormState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });
}

class TaskFormNotifier extends StateNotifier<TaskFormState> {
  final TaskRepository? _repository;
  final MockTaskRepository? _mockRepo;

  TaskFormNotifier({TaskRepository? repository, MockTaskRepository? mockRepo})
      : _repository = repository,
        _mockRepo = mockRepo,
        super(const TaskFormState());

  Future<TaskModel?> createTask({
    required String title,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    String? dueTime,
    String? categoryId,
    List<String> tags = const [],
    int estimatedMinutes = 0,
    bool isRecurring = false,
    String? recurringPattern,
  }) async {
    state = const TaskFormState(isLoading: true);
    try {
      final data = {
        'title': title,
        if (description != null) 'description': description,
        'priority': priority.value,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (dueTime != null) 'dueTime': dueTime,
        if (categoryId != null) 'categoryId': categoryId,
        'tags': tags,
        'estimatedMinutes': estimatedMinutes,
        'isRecurring': isRecurring,
        if (recurringPattern != null) 'recurringPattern': recurringPattern,
      };
      final task = kUseMock
          ? await _mockRepo!.createTask(data)
          : await _repository!.createTask(
              title: title,
              description: description,
              priority: priority,
              dueDate: dueDate,
              dueTime: dueTime,
              categoryId: categoryId,
              tags: tags,
              estimatedMinutes: estimatedMinutes,
              isRecurring: isRecurring,
              recurringPattern: recurringPattern,
            );
      state = const TaskFormState(isSuccess: true);
      return task;
    } catch (e) {
      state = TaskFormState(errorMessage: e.toString());
      return null;
    }
  }

  Future<TaskModel?> updateTask({
    required String id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? dueTime,
    String? categoryId,
    List<String>? tags,
    int? estimatedMinutes,
  }) async {
    state = const TaskFormState(isLoading: true);
    try {
      TaskModel task;
      if (kUseMock) {
        final data = <String, dynamic>{};
        if (title != null) data['title'] = title;
        if (description != null) data['description'] = description;
        if (priority != null) data['priority'] = priority.value;
        if (status != null) data['status'] = status.value;
        if (dueDate != null) data['dueDate'] = dueDate.toIso8601String();
        if (dueTime != null) data['dueTime'] = dueTime;
        if (categoryId != null) data['categoryId'] = categoryId;
        if (tags != null) data['tags'] = tags;
        if (estimatedMinutes != null) data['estimatedMinutes'] = estimatedMinutes;
        task = await _mockRepo!.updateTask(id, data);
      } else {
        task = await _repository!.updateTask(
          id: id,
          title: title,
          description: description,
          priority: priority,
          status: status,
          dueDate: dueDate,
          dueTime: dueTime,
          categoryId: categoryId,
          tags: tags,
          estimatedMinutes: estimatedMinutes,
        );
      }
      state = const TaskFormState(isSuccess: true);
      return task;
    } catch (e) {
      state = TaskFormState(errorMessage: e.toString());
      return null;
    }
  }

  void reset() => state = const TaskFormState();
}

final taskFormProvider =
    StateNotifierProvider.autoDispose<TaskFormNotifier, TaskFormState>((ref) {
  if (kUseMock) {
    return TaskFormNotifier(mockRepo: ref.watch(mockTaskRepositoryProvider));
  }
  return TaskFormNotifier(repository: ref.watch(taskRepositoryProvider));
});

