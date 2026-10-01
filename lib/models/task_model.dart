// lib/models/task_model.dart

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { pending, inProgress, completed, cancelled }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  String get value {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.urgent:
        return 'urgent';
    }
  }

  static TaskPriority fromString(String value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      case 'low':
        return TaskPriority.low;
      default:
        return TaskPriority.medium;
    }
  }
}

extension TaskStatusExtension on TaskStatus {
  String get value {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  static TaskStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  bool get isDone => this == TaskStatus.completed;
}

class TaskCategory {
  final String id;
  final String name;
  final String color; // hex string e.g. '#6C63FF'
  final String? icon;
  final String userId;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.userId,
  });

  factory TaskCategory.fromJson(Map<String, dynamic> json) {
    return TaskCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6C63FF',
      icon: json['icon'] as String?,
      userId: json['userId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'userId': userId,
      };

  TaskCategory copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    String? userId,
  }) {
    return TaskCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      userId: userId ?? this.userId,
    );
  }
}

class SubTask {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  SubTask copyWith({String? id, String? title, bool? isCompleted}) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final String? dueTime; // HH:mm
  final String? categoryId;
  final TaskCategory? category;
  final List<SubTask> subTasks;
  final List<String> tags;
  final bool isRecurring;
  final String? recurringPattern; // daily, weekly, monthly
  final int estimatedMinutes;
  final int actualMinutes;
  final int tokenReward;
  final int xpReward;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.dueDate,
    this.dueTime,
    this.categoryId,
    this.category,
    this.subTasks = const [],
    this.tags = const [],
    this.isRecurring = false,
    this.recurringPattern,
    this.estimatedMinutes = 0,
    this.actualMinutes = 0,
    this.tokenReward = 5,
    this.xpReward = 10,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      !isCompleted;

  double get subTaskProgress {
    if (subTasks.isEmpty) return 0;
    final done = subTasks.where((s) => s.isCompleted).length;
    return done / subTasks.length;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriorityExtension.fromString(
          json['priority'] as String? ?? 'medium'),
      status: TaskStatusExtension.fromString(
          json['status'] as String? ?? 'pending'),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dueTime: json['dueTime'] as String?,
      categoryId: json['categoryId'] as String?,
      category: json['category'] != null
          ? TaskCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      subTasks: (json['subTasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringPattern: json['recurringPattern'] as String?,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
      actualMinutes: json['actualMinutes'] as int? ?? 0,
      tokenReward: json['tokenReward'] as int? ?? 5,
      xpReward: json['xpReward'] as int? ?? 10,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'priority': priority.value,
        'status': status.value,
        'dueDate': dueDate?.toIso8601String(),
        'dueTime': dueTime,
        'categoryId': categoryId,
        'subTasks': subTasks.map((s) => s.toJson()).toList(),
        'tags': tags,
        'isRecurring': isRecurring,
        'recurringPattern': recurringPattern,
        'estimatedMinutes': estimatedMinutes,
        'actualMinutes': actualMinutes,
        'tokenReward': tokenReward,
        'xpReward': xpReward,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? dueTime,
    String? categoryId,
    TaskCategory? category,
    List<SubTask>? subTasks,
    List<String>? tags,
    bool? isRecurring,
    String? recurringPattern,
    int? estimatedMinutes,
    int? actualMinutes,
    int? tokenReward,
    int? xpReward,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      subTasks: subTasks ?? this.subTasks,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      tokenReward: tokenReward ?? this.tokenReward,
      xpReward: xpReward ?? this.xpReward,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ── Pagination wrapper ──────────────────────────────────────
class PaginatedTasks {
  final List<TaskModel> tasks;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedTasks({
    required this.tasks,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedTasks.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>;
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final total = meta['total'] as int? ?? data.length;
    final page = meta['page'] as int? ?? 1;
    final pageSize = meta['pageSize'] as int? ?? 20;
    return PaginatedTasks(
      tasks: data
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
      page: page,
      pageSize: pageSize,
      hasMore: (page * pageSize) < total,
    );
  }
}
