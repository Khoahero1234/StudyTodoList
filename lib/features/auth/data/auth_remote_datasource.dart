// lib/features/auth/data/auth_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_exception.dart';
import '../../../models/user_model.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  const AuthRemoteDataSource(this._dioClient);

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'username': username,
        },
      );
      return AuthResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dioClient.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Map<String, String>> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      return {
        'accessToken': data['accessToken'] as String,
        'refreshToken': data['refreshToken'] as String? ?? refreshToken,
      };
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dioClient.get(ApiEndpoints.me);
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dioClient.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _dioClient.post(
        ApiEndpoints.resetPassword,
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
