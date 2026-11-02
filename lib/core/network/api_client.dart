// lib/core/network/api_client.dart

import 'package:dio/dio.dart';
import 'dio_client.dart';

class ApiClient {
  final DioClient _dioClient;

  ApiClient(this._dioClient);

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dioClient.get(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dioClient.post(path, data: data, queryParameters: queryParameters);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dioClient.put(path, data: data);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dioClient.patch(path, data: data);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await _dioClient.delete(path);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleResponse(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final success = body['success'];
      if (success == false) {
        final errorMsg = body['error'] ?? body['message'] ?? 'Unknown API error';
        throw Exception(errorMsg);
      }
      return body['data'] ?? body;
    }
    return body;
  }

  Exception _handleError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    if (error is DioException) {
      if (error.response?.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        final errMsg = data['error'] ?? data['message'];
        if (errMsg != null) {
          return Exception(errMsg.toString());
        }
      }
      return Exception(error.message ?? 'Network connection error');
    }
    return Exception(error.toString());
  }
}
