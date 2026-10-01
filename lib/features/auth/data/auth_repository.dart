// lib/features/auth/data/auth_repository.dart
import '../../../core/constants/storage_keys.dart';
import '../../../core/network/network_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../models/user_model.dart';
import 'auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorage _secureStorage;

  const AuthRepository(this._remoteDataSource, this._secureStorage);

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    await _saveTokens(response.accessToken, response.refreshToken);
    await _secureStorage.write(StorageKeys.userId, response.user.id);
    return response.user;
  }

  Future<UserModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _remoteDataSource.register(
      email: email,
      password: password,
      username: username,
    );
    await _saveTokens(response.accessToken, response.refreshToken);
    await _secureStorage.write(StorageKeys.userId, response.user.id);
    return response.user;
  }

  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Logout locally even if request fails
    } finally {
      await _clearTokens();
    }
  }

  /// Returns user if a valid session exists, null otherwise.
  Future<UserModel?> tryAutoLogin() async {
    final token = await _secureStorage.read(StorageKeys.accessToken);
    if (token == null || token.isEmpty) return null;

    try {
      return await _remoteDataSource.getMe();
    } on NetworkException catch (e) {
      if (e.statusCode == 401) {
        // Try refresh
        final refresh = await _secureStorage.read(StorageKeys.refreshToken);
        if (refresh == null || refresh.isEmpty) {
          await _clearTokens();
          return null;
        }
        try {
          final tokens = await _remoteDataSource.refreshToken(refresh);
          await _saveTokens(tokens['accessToken']!, tokens['refreshToken']!);
          return await _remoteDataSource.getMe();
        } catch (_) {
          await _clearTokens();
          return null;
        }
      }
      return null;
    }
  }

  Future<UserModel> getMe() async {
    return _remoteDataSource.getMe();
  }

  Future<void> forgotPassword(String email) async {
    return _remoteDataSource.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return _remoteDataSource.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }

  Future<bool> hasValidSession() async {
    final token = await _secureStorage.read(StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(StorageKeys.accessToken, accessToken);
    await _secureStorage.write(StorageKeys.refreshToken, refreshToken);
  }

  Future<void> _clearTokens() async {
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
    await _secureStorage.delete(StorageKeys.userId);
  }
}
