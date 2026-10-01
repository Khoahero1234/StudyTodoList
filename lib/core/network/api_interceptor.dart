// lib/core/network/api_interceptor.dart
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../constants/storage_keys.dart';
import '../storage/secure_storage.dart';

class ApiInterceptor extends Interceptor {
  final SecureStorage _secureStorage;
  final Dio _dio;
  bool _isRefreshing = false;

  ApiInterceptor(this._secureStorage, this._dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken =
            await _secureStorage.read(StorageKeys.refreshToken);
        if (refreshToken == null || refreshToken.isEmpty) {
          _isRefreshing = false;
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          ApiEndpoints.refreshToken,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': ''}),
        );

        final newAccessToken =
            response.data['accessToken'] as String;
        final newRefreshToken =
            response.data['refreshToken'] as String?;

        await _secureStorage.write(StorageKeys.accessToken, newAccessToken);
        if (newRefreshToken != null) {
          await _secureStorage.write(
              StorageKeys.refreshToken, newRefreshToken);
        }

        // Retry original request with new token
        err.requestOptions.headers['Authorization'] =
            'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        // Refresh failed — clear tokens, force re-login
        await _secureStorage.delete(StorageKeys.accessToken);
        await _secureStorage.delete(StorageKeys.refreshToken);
        await _secureStorage.delete(StorageKeys.userId);
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}
