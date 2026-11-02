// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/tasks/screens/task_list_screen.dart';
import '../../features/tasks/screens/task_form_screen.dart';
import '../../features/tasks/screens/task_detail_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/ai/screens/ai_chat_screen.dart';
import '../../features/shop/screens/shop_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/pomodoro/screens/pomodoro_screen.dart';
import '../../features/pet/screens/pet_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';
import '../../features/premium/screens/premium_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/study_room/screens/study_room_screen.dart';
import '../../features/rewards/screens/reward_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

// Route names
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const tasks = '/home/tasks';
  static const taskNew = '/tasks/new';
  static const taskDetail = '/tasks/:id';
  static const taskEdit = '/tasks/:id/edit';
  static const calendar = '/home/calendar';
  static const ai = '/home/ai';
  static const shop = '/home/shop';
  static const profile = '/home/profile';
  static const pomodoro = '/pomodoro';
  static const pomodoroTask = '/pomodoro/:taskId';
  static const pet = '/pet';
  static const wallet = '/wallet';
  static const premium = '/premium';
  static const inventory = '/inventory';
  static const studyRooms = '/study-rooms';
  static const studyRoomDetail = '/study-rooms/:id';
  static const rewards = '/rewards';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthStatus>(AuthStatus.initial);
  
  ref.listen<AuthState>(authProvider, (previous, next) {
    authNotifier.value = next.status;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final status = ref.read(authProvider).status;
      final location = state.uri.toString();

      // Only the initial state belongs on the splash screen. Loading can also
      // happen during login, registration, or logout, so keep the current route.
      if (status == AuthStatus.initial) {
        if (location != AppRoutes.splash) return AppRoutes.splash;
        return null;
      }

      if (status == AuthStatus.loading) {
        return null;
      }

      final isAuthenticated = status == AuthStatus.authenticated;

      if (location == AppRoutes.splash) {
        return isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Shell route with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.tasks,
            builder: (context, state) => const TaskListScreen(),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.ai,
            builder: (context, state) => const AiChatScreen(),
          ),
          GoRoute(
            path: AppRoutes.shop,
            builder: (context, state) => const ShopScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: AppRoutes.taskNew,
        builder: (context, state) => const TaskFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: AppRoutes.taskEdit,
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskFormScreen(taskId: taskId);
        },
      ),
      GoRoute(
        path: AppRoutes.pomodoro,
        builder: (context, state) => const PomodoroScreen(),
      ),
      GoRoute(
        path: AppRoutes.pet,
        builder: (context, state) => const PetScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallet,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: AppRoutes.inventory,
        builder: (context, state) => const InventoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.studyRooms,
        builder: (context, state) => const StudyRoomScreen(),
      ),
      GoRoute(
        path: AppRoutes.rewards,
        builder: (context, state) => const RewardScreen(),
      ),
    ],
  );
});
