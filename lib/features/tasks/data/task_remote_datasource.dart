// lib/features/tasks/data/task_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/task_model.dart';

class TaskRemoteDataSource {
  final DioClient _dioClient;

  TaskRemoteDataSource(this._dioClient);

  Future<PaginatedTasks> getTasks({
    required int page,
    TaskStatus? status,
    TaskPriority? priority,
    String? categoryId,
    String? search,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) async {
    final Map<String, dynamic> query = {'page': page};
    if (status != null) query['status'] = status.value;
    if (priority != null) query['priority'] = priority.value;
    if (categoryId != null) query['categoryId'] = categoryId;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (dueDateFrom != null) query['dueDateFrom'] = dueDateFrom.toIso8601String();
    if (dueDateTo != null) query['dueDateTo'] = dueDateTo.toIso8601String();

    try {
      final response = await _dioClient.get(
        '/tasks',
        queryParameters: query,
      );
      return PaginatedTasks.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<TaskModel> getTaskById(String id) async {
    try {
      final response = await _dioClient.get('/tasks/$id');
      return TaskModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to get task: $e');
    }
  }

  Future<TaskModel> createTask(Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.post('/tasks', data: data);
      return TaskModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<TaskModel> updateTask(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dioClient.patch('/tasks/$id', data: data);
      return TaskModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dioClient.delete('/tasks/$id');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<TaskModel> completeTask(String id) async {
    try {
      final response = await _dioClient.patch('/tasks/$id/complete');
      return TaskModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }
}
