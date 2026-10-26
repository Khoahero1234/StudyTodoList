// lib/core/mock/mock_task_repository.dart
// ─── Repository giả thay thế TaskRepository khi kUseMock = true ───
import 'dart:async';
import '../../models/task_model.dart';
import 'mock_data.dart';

class MockTaskRepository {
  // Danh sách task trong bộ nhớ (có thể thêm/sửa/xóa trong session)
  final List<TaskModel> _tasks = List.from(mockTasks);

  Future<PaginatedTasks> getTasks({
    required int page,
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    String? search,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    var filtered = _tasks.where((t) {
      if (status != null && t.status != status) return false;
      if (priority != null && t.priority != priority) return false;
      if (categoryId != null && t.categoryId != categoryId) return false;
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        if (!t.title.toLowerCase().contains(q) &&
            !(t.description?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      if (dueDateFrom != null &&
          t.dueDate != null &&
          t.dueDate!.isBefore(dueDateFrom)) {
        return false;
      }
      if (dueDateTo != null &&
          t.dueDate != null &&
          t.dueDate!.isAfter(dueDateTo)) {
        return false;
      }
      return true;
    }).toList();

    // Sắp xếp: urgent/high trước, rồi theo due date
    filtered.sort((a, b) {
      final priorityOrder = {
        TaskPriority.urgent: 0,
        TaskPriority.high: 1,
        TaskPriority.medium: 2,
        TaskPriority.low: 3,
      };
      final pa = priorityOrder[a.priority] ?? 2;
      final pb = priorityOrder[b.priority] ?? 2;
      if (pa != pb) return pa.compareTo(pb);
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      return 0;
    });

    const pageSize = 20;
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    final paginated = start < filtered.length ? filtered.sublist(start, end) : <TaskModel>[];

    return PaginatedTasks(
      tasks: paginated,
      total: filtered.length,
      page: page,
      pageSize: pageSize,
      hasMore: end < filtered.length,
    );
  }

  Future<TaskModel> getTaskById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final task = _tasks.firstWhere(
      (t) => t.id == id,
      orElse: () => throw Exception('Task không tìm thấy: $id'),
    );
    return task;
  }

  Future<TaskModel> createTask(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final task = TaskModel(
      id: 'task-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'mock-user-001',
      title: data['title'] as String,
      description: data['description'] as String?,
      priority: data['priority'] != null
          ? TaskPriorityExtension.fromString(data['priority'] as String)
          : TaskPriority.medium,
      status: TaskStatus.pending,
      dueDate: data['dueDate'] != null
          ? DateTime.parse(data['dueDate'] as String)
          : null,
      dueTime: data['dueTime'] as String?,
      categoryId: data['categoryId'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      estimatedMinutes: data['estimatedMinutes'] as int? ?? 0,
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringPattern: data['recurringPattern'] as String?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks.insert(0, task);
    return task;
  }

  Future<TaskModel> updateTask(String id, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw Exception('Task không tìm thấy: $id');

    final old = _tasks[index];
    final updated = old.copyWith(
      title: data['title'] as String? ?? old.title,
      description: data['description'] as String? ?? old.description,
      priority: data['priority'] != null
          ? TaskPriorityExtension.fromString(data['priority'] as String)
          : old.priority,
      status: data['status'] != null
          ? TaskStatusExtension.fromString(data['status'] as String)
          : old.status,
      dueDate: data['dueDate'] != null
          ? DateTime.parse(data['dueDate'] as String)
          : old.dueDate,
      dueTime: data['dueTime'] as String? ?? old.dueTime,
      categoryId: data['categoryId'] as String? ?? old.categoryId,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? old.tags,
      subTasks: data['subTasks'] != null
          ? (data['subTasks'] as List<dynamic>)
              .map((e) => e is SubTask ? e : SubTask.fromJson(e as Map<String, dynamic>))
              .toList()
          : old.subTasks,
      estimatedMinutes:
          data['estimatedMinutes'] as int? ?? old.estimatedMinutes,
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  Future<void> deleteTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _tasks.removeWhere((t) => t.id == id);
  }

  Future<TaskModel> completeTask(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw Exception('Task không tìm thấy: $id');
    final completed = _tasks[index].copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks[index] = completed;
    return completed;
  }
}
