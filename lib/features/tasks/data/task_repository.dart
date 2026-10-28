// lib/features/tasks/data/task_repository.dart
import '../../../models/task_model.dart';
import 'task_remote_datasource.dart';

class TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;

  TaskRepository(this._remoteDataSource);

  Future<PaginatedTasks> getTasks({
    required int page,
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    String? search,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) {
    return _remoteDataSource.getTasks(
      page: page,
      status: status,
      priority: priority,
      categoryId: categoryId,
      search: search,
      dueDateFrom: dueDateFrom,
      dueDateTo: dueDateTo,
    );
  }

  Future<TaskModel> getTaskById(String id) {
    return _remoteDataSource.getTaskById(id);
  }

  Future<TaskModel> createTask({
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
  }) {
    return _remoteDataSource.createTask({
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
    });
  }

  Future<TaskModel> updateTask({
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
  }) {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (priority != null) data['priority'] = priority.value;
    if (status != null) data['status'] = status.value;
    if (dueDate != null) data['dueDate'] = dueDate.toIso8601String();
    if (dueTime != null) data['dueTime'] = dueTime;
    if (categoryId != null) data['categoryId'] = categoryId;
    if (tags != null) data['tags'] = tags;
    if (estimatedMinutes != null) data['estimatedMinutes'] = estimatedMinutes;

    return _remoteDataSource.updateTask(id, data);
  }

  Future<void> deleteTask(String id) {
    return _remoteDataSource.deleteTask(id);
  }

  Future<TaskModel> completeTask(String id) {
    return _remoteDataSource.completeTask(id);
  }
}
