// lib/features/tasks/providers/task_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/mock/mock_task_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/wallet/providers/wallet_provider.dart';
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
  final Ref _ref;

  TaskListNotifier({TaskRepository? repository, MockTaskRepository? mockRepo, required Ref ref})
      : _repository = repository,
        _mockRepo = mockRepo,
        _ref = ref,
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
      final taskBefore = state.tasks.firstWhere((t) => t.id == id, orElse: () => state.tasks.first);
      final updated = kUseMock
          ? await _mockRepo!.completeTask(id)
          : await _repository!.completeTask(id);
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == id ? updated : t).toList(),
      );
      if (!taskBefore.isCompleted && updated.isCompleted) {
        _ref.read(authProvider.notifier).addTokens(updated.tokenReward);
        _ref.read(walletProvider.notifier).addRewardTransaction(updated.tokenReward, updated.title);
      }
      _ref.read(authProvider.notifier).refreshUser();
    } catch (_) {}
  }

  Future<void> toggleTaskCompletion(String id) async {
    final task = state.tasks.firstWhere(
      (t) => t.id == id,
      orElse: () => TaskModel(
        id: id,
        userId: '',
        title: '',
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final isCompleting = !task.isCompleted;

    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.id != id) return t;
        return t.copyWith(
          status: isCompleting ? TaskStatus.completed : TaskStatus.pending,
          completedAt: isCompleting ? DateTime.now() : null,
        );
      }).toList(),
    );

    try {
      TaskModel updatedTask;
      if (kUseMock) {
        if (isCompleting) {
          updatedTask = await _mockRepo!.completeTask(id);
        } else {
          updatedTask = await _mockRepo!.updateTask(id, {'status': 'PENDING'});
        }
      } else {
        if (isCompleting) {
          updatedTask = await _repository!.completeTask(id);
        } else {
          updatedTask = await _repository!.updateTask(id: id, status: TaskStatus.pending);
        }
      }
      if (isCompleting) {
        _ref.read(authProvider.notifier).addTokens(updatedTask.tokenReward);
        _ref.read(walletProvider.notifier).addRewardTransaction(updatedTask.tokenReward, updatedTask.title);
      }
      _ref.read(authProvider.notifier).refreshUser();
    } catch (_) {}
  }

  Future<void> deleteTask(String id) async {
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != id).toList(),
    );
    try {
      if (kUseMock) {
        await _mockRepo!.deleteTask(id);
      } else {
        await _repository!.deleteTask(id);
      }
    } catch (_) {}
  }

  void addTask(TaskModel task) {
    state = state.copyWith(tasks: [task, ...state.tasks]);
  }

  void updateTask(TaskModel updated) {
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.id == updated.id ? updated : t).toList(),
    );
  }
}

final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final mockRepo = ref.watch(mockTaskRepositoryProvider);
  return TaskListNotifier(repository: repository, mockRepo: mockRepo, ref: ref);
});

final todayTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(taskListProvider).tasks;
  final now = DateTime.now();
  return tasks.where((t) {
    final isDueToday = t.dueDate != null &&
        t.dueDate!.year == now.year &&
        t.dueDate!.month == now.month &&
        t.dueDate!.day == now.day;
    final isCompletedToday = t.completedAt != null &&
        t.completedAt!.year == now.year &&
        t.completedAt!.month == now.month &&
        t.completedAt!.day == now.day;
    return isDueToday || isCompletedToday;
  }).toList();
});

// ─── Task Form State & Notifier ──────────────────────────────
class TaskFormState {
  final bool isLoading;
  final String? errorMessage;

  const TaskFormState({
    this.isLoading = false,
    this.errorMessage,
  });

  TaskFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TaskFormNotifier extends StateNotifier<TaskFormState> {
  final TaskRepository? _repository;
  final MockTaskRepository? _mockRepo;
  final Ref _ref;

  TaskFormNotifier({TaskRepository? repository, MockTaskRepository? mockRepo, required Ref ref})
      : _repository = repository,
        _mockRepo = mockRepo,
        _ref = ref,
        super(const TaskFormState());

  void reset() {
    state = const TaskFormState();
  }

  Future<TaskModel?> createTask({
    required String title,
    String? description,
    required TaskPriority priority,
    DateTime? dueDate,
    String? dueTime,
    String? categoryId,
    List<String> tags = const [],
    int estimatedMinutes = 0,
    bool isRecurring = false,
    String? recurringPattern,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      TaskModel task;
      if (kUseMock) {
        task = await _mockRepo!.createTask({
          'title': title,
          'description': description,
          'priority': priority.name.toUpperCase(),
          'dueDate': dueDate?.toIso8601String(),
          'dueTime': dueTime,
          'categoryId': categoryId,
          'tags': tags,
          'estimatedMinutes': estimatedMinutes,
          'isRecurring': isRecurring,
          'recurringPattern': recurringPattern,
        });
      } else {
        task = await _repository!.createTask(
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
      }
      _ref.read(taskListProvider.notifier).addTask(task);
      _ref.read(walletProvider.notifier).refreshWallet();
      _ref.read(authProvider.notifier).refreshUser();
      state = state.copyWith(isLoading: false);
      return task;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<TaskModel?> updateTask({
    required String id,
    required String title,
    String? description,
    required TaskPriority priority,
    DateTime? dueDate,
    String? dueTime,
    String? categoryId,
    List<String> tags = const [],
    int estimatedMinutes = 0,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      TaskModel task;
      if (kUseMock) {
        task = await _mockRepo!.updateTask(id, {
          'title': title,
          'description': description,
          'priority': priority.name.toUpperCase(),
          'dueDate': dueDate?.toIso8601String(),
          'dueTime': dueTime,
          'categoryId': categoryId,
          'tags': tags,
          'estimatedMinutes': estimatedMinutes,
        });
      } else {
        task = await _repository!.updateTask(
          id: id,
          title: title,
          description: description,
          priority: priority,
          dueDate: dueDate,
          dueTime: dueTime,
          categoryId: categoryId,
          tags: tags,
          estimatedMinutes: estimatedMinutes,
        );
      }
      _ref.read(taskListProvider.notifier).updateTask(task);
      state = state.copyWith(isLoading: false);
      return task;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

final taskFormProvider =
    StateNotifierProvider<TaskFormNotifier, TaskFormState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final mockRepo = ref.watch(mockTaskRepositoryProvider);
  return TaskFormNotifier(repository: repository, mockRepo: mockRepo, ref: ref);
});
