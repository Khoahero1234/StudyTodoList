// lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';

  // Users
  static const String me = '/auth/me';
  static String userById(String id) => '/users/$id';

  // Tasks
  static const String tasks = '/tasks';
  static String taskById(String id) => '/tasks/$id';
  static String completeTask(String id) => '/tasks/$id/complete';
  static const String taskCategories = '/tasks/categories';
  static String taskCategoryById(String id) => '/tasks/categories/$id';

  // Calendar
  static const String calendar = '/calendar';

  // AI
  static const String aiChat = '/ai/chat';
  static const String aiParseTask = '/ai/parse-task';
  static const String aiBreakdown = '/ai/breakdown';
  static const String aiDailyPlan = '/ai/daily-plan';
  static const String aiPriority = '/ai/priority';

  // Conversations
  static const String conversations = '/conversations';
  static String conversationById(String id) => '/conversations/$id';
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';

  // Study Rooms
  static const String studyRooms = '/study-rooms';
  static String studyRoomById(String id) => '/study-rooms/$id';
  static String joinStudyRoom(String id) => '/study-rooms/$id/join';
  static String leaveStudyRoom(String id) => '/study-rooms/$id/leave';

  // Shop
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
  static const String productCategories = '/product-categories';

  // Orders
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';

  // Wallet
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';

  // Inventory
  static const String inventory = '/inventory';
  static String equipItem(String itemId) => '/inventory/$itemId/equip';
  static String unequipItem(String itemId) => '/inventory/$itemId/unequip';

  // Premium
  static const String premiumPlans = '/premium/plans';
  static const String premiumSubscribe = '/premium/subscribe';
  static const String premiumStatus = '/premium/status';

  // Pomodoro
  static const String pomodoroSessions = '/pomodoro/sessions';
  static String pomodoroSessionById(String id) => '/pomodoro/sessions/$id';

  // Pet
  static const String pet = '/pet';
  static const String feedPet = '/pet/feed';
  static const String playWithPet = '/pet/play';

  // Notifications
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) =>
      '/notifications/$id/read';

  // Friends
  static const String friends = '/friends';
  static const String friendRequests = '/friends/requests';
  static String acceptFriendRequest(String id) =>
      '/friends/requests/$id/accept';
  static String declineFriendRequest(String id) =>
      '/friends/requests/$id/decline';

  // Productivity
  static const String productivityStats = '/productivity/stats';
  static const String loginStreak = '/productivity/streak';
  static const String rewards = '/rewards';
  static String claimReward(String id) => '/rewards/$id/claim';

  // Admin
  static const String adminUsers = '/admin/users';
  static String adminUserStatus(String id) => '/admin/users/$id/status';
  static const String adminProducts = '/admin/products';
  static String adminProductById(String id) => '/admin/products/$id';
  static const String adminStats = '/admin/stats';
}
