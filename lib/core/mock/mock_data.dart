// lib/core/mock/mock_data.dart
// ─── Dữ liệu cứng dùng để phát triển FE mà không cần backend ───
import '../../models/task_model.dart';
import '../../models/user_model.dart';

/// Flag để bật/tắt chế độ mock.
/// Đặt thành false khi backend đã sẵn sàng.
const bool kUseMock = true;

// ─── Mock User ───────────────────────────────────────────────────────────────

final mockUser = UserModel(
  id: 'mock-user-001',
  email: 'demo@studytodo.app',
  username: 'Demo User',
  avatarUrl: null,
  role: 'customer',
  isActive: true,
  emailVerified: true,
  isPremium: false,
  tokenBalance: 250,
  currentStreak: 5,
  longestStreak: 14,
  lastLoginDate: DateTime.now(),
  createdAt: DateTime(2024, 1, 15),
  updatedAt: DateTime.now(),
);

/// Tài khoản được chấp nhận khi login mock
/// email + password bất kỳ đều đăng nhập thành công
/// Nhưng nếu muốn giới hạn, dùng danh sách này:
const mockAcceptedEmail = 'demo@studytodo.app';
const mockAcceptedPassword = '123456';

// ─── Mock Tasks ──────────────────────────────────────────────────────────────

final _now = DateTime.now();

final mockTasks = <TaskModel>[
  TaskModel(
    id: 'task-001',
    userId: 'mock-user-001',
    title: 'Ôn tập Dart cơ bản',
    description: 'Xem lại syntax, async/await, null safety',
    priority: TaskPriority.high,
    status: TaskStatus.completed,
    dueDate: _now.subtract(const Duration(days: 1)),
    dueTime: '09:00',
    tags: ['dart', 'flutter'],
    estimatedMinutes: 60,
    actualMinutes: 55,
    tokenReward: 10,
    xpReward: 20,
    completedAt: _now.subtract(const Duration(hours: 18)),
    createdAt: _now.subtract(const Duration(days: 2)),
    updatedAt: _now.subtract(const Duration(hours: 18)),
    subTasks: [
      const SubTask(id: 'st-001', title: 'Xem lại Future & Stream', isCompleted: true),
      const SubTask(id: 'st-002', title: 'Null safety exercises', isCompleted: true),
    ],
  ),
  TaskModel(
    id: 'task-002',
    userId: 'mock-user-001',
    title: 'Hoàn thành bài tập Flutter',
    description: 'Làm UI cho màn hình danh sách task',
    priority: TaskPriority.urgent,
    status: TaskStatus.inProgress,
    dueDate: _now,
    dueTime: '23:59',
    tags: ['flutter', 'assignment'],
    estimatedMinutes: 120,
    tokenReward: 15,
    xpReward: 30,
    createdAt: _now.subtract(const Duration(days: 1)),
    updatedAt: _now,
    subTasks: [
      const SubTask(id: 'st-003', title: 'Thiết kế màn hình danh sách', isCompleted: true),
      const SubTask(id: 'st-004', title: 'Kết nối provider', isCompleted: false),
      const SubTask(id: 'st-005', title: 'Test UI trên thiết bị', isCompleted: false),
    ],
  ),
  TaskModel(
    id: 'task-003',
    userId: 'mock-user-001',
    title: 'Đọc sách Clean Code',
    description: 'Chương 3–5: Functions, Comments, Formatting',
    priority: TaskPriority.medium,
    status: TaskStatus.pending,
    dueDate: _now.add(const Duration(days: 2)),
    dueTime: '20:00',
    tags: ['reading', 'self-improvement'],
    estimatedMinutes: 45,
    tokenReward: 8,
    xpReward: 15,
    createdAt: _now.subtract(const Duration(days: 3)),
    updatedAt: _now.subtract(const Duration(days: 3)),
  ),
  TaskModel(
    id: 'task-004',
    userId: 'mock-user-001',
    title: 'Họp nhóm dự án PRM',
    description: 'Báo cáo tiến độ tuần và phân công công việc',
    priority: TaskPriority.high,
    status: TaskStatus.pending,
    dueDate: _now.add(const Duration(days: 1)),
    dueTime: '15:00',
    tags: ['meeting', 'prm393'],
    estimatedMinutes: 60,
    tokenReward: 5,
    xpReward: 10,
    createdAt: _now.subtract(const Duration(days: 1)),
    updatedAt: _now.subtract(const Duration(days: 1)),
  ),
  TaskModel(
    id: 'task-005',
    userId: 'mock-user-001',
    title: 'Tập thể dục buổi sáng',
    description: '30 phút cardio + stretching',
    priority: TaskPriority.low,
    status: TaskStatus.pending,
    dueDate: _now.add(const Duration(days: 1)),
    dueTime: '06:30',
    tags: ['health', 'daily'],
    isRecurring: true,
    recurringPattern: 'daily',
    estimatedMinutes: 30,
    tokenReward: 5,
    xpReward: 10,
    createdAt: _now.subtract(const Duration(days: 7)),
    updatedAt: _now,
  ),
  TaskModel(
    id: 'task-006',
    userId: 'mock-user-001',
    title: 'Nộp báo cáo môn CSD',
    description: 'Báo cáo phân tích hệ thống cơ sở dữ liệu',
    priority: TaskPriority.urgent,
    status: TaskStatus.pending,
    dueDate: _now.add(const Duration(days: 3)),
    dueTime: '23:59',
    tags: ['school', 'report'],
    estimatedMinutes: 180,
    tokenReward: 20,
    xpReward: 40,
    createdAt: _now.subtract(const Duration(days: 5)),
    updatedAt: _now.subtract(const Duration(days: 5)),
  ),
];

// ─── Mock Categories ─────────────────────────────────────────────────────────

final mockCategories = <TaskCategory>[
  const TaskCategory(id: 'cat-001', name: 'Học tập', color: '#6C63FF', icon: 'book', userId: 'mock-user-001'),
  const TaskCategory(id: 'cat-002', name: 'Công việc', color: '#FF6584', icon: 'work', userId: 'mock-user-001'),
  const TaskCategory(id: 'cat-003', name: 'Sức khỏe', color: '#43D17A', icon: 'fitness_center', userId: 'mock-user-001'),
  const TaskCategory(id: 'cat-004', name: 'Cá nhân', color: '#F5A623', icon: 'person', userId: 'mock-user-001'),
];
