// lib/features/auth/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_auth_repository.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/user_model.dart';
import '../data/auth_remote_datasource.dart';
import '../data/auth_repository.dart';

// ─── Infrastructure Providers ────────────────────────────────────────

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DioClient(secureStorage);
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dioClient);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(remote, storage);
});

// ─── Auth State ──────────────────────────────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null;

  const AuthState.authenticated(UserModel user)
      : status = AuthStatus.authenticated,
        user = user,
        errorMessage = null;

  const AuthState.unauthenticated([String? error])
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ─── Auth Notifier ───────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository? _repository;
  final MockAuthRepository? _mockRepository;

  /// Khi kUseMock = true, dùng _mockRepository; ngược lại dùng _repository.
  AuthNotifier.real(AuthRepository repository)
      : _repository = repository,
        _mockRepository = null,
        super(const AuthState.initial());

  AuthNotifier.mock(MockAuthRepository mockRepository)
      : _repository = null,
        _mockRepository = mockRepository,
        super(const AuthState.initial());

  // Deprecated constructor kept for backward compat; prefer named constructors
  AuthNotifier(AuthRepository repository)
      : _repository = repository,
        _mockRepository = null,
        super(const AuthState.initial());

  /// Called on app startup — tries to restore the session.
  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();
    try {
      final user = kUseMock
          ? await _mockRepository!.tryAutoLogin()
          : await _repository!.tryAutoLogin();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = kUseMock
          ? await _mockRepository!.login(email: email, password: password)
          : await _repository!.login(email: email, password: password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AuthState.loading();
    try {
      final user = kUseMock
          ? await _mockRepository!.register(
              email: email, password: password, username: username)
          : await _repository!.register(
              email: email, password: password, username: username);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    if (kUseMock) {
      await _mockRepository!.logout();
    } else {
      await _repository!.logout();
    }
    state = const AuthState.unauthenticated();
  }

  Future<void> updateProfile({
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      UserModel? updatedUser;
      if (kUseMock) {
        final currentUser = state.user;
        if (currentUser != null) {
          // Tạo UserModel mới với username đã thay đổi để app nhận ngay lập tức
          updatedUser = currentUser.copyWith(
            username: username ?? currentUser.username,
          );
        }
      } else {
        updatedUser = await _repository!.updateProfile(
          displayName: displayName,
          username: username,
          bio: bio,
          avatarUrl: avatarUrl,
        );
      }

      if (updatedUser != null) {
        state = AuthState.authenticated(updatedUser);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!kUseMock) {
      await _repository!.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    if (kUseMock) {
      await _mockRepository!.forgotPassword(email);
    } else {
      await _repository!.forgotPassword(email);
    }
  }

  void updateUser(UserModel user) {
    state = AuthState.authenticated(user);
  }

  void clearError() {
    if (state.status == AuthStatus.unauthenticated) {
      state = const AuthState.unauthenticated();
    }
  }
}

// ─── Auth Provider ───────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  if (kUseMock) {
    return AuthNotifier.mock(MockAuthRepository());
  }
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier.real(repository);
});

// Convenience providers
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
