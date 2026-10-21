// lib/features/wallet/data/wallet_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class WalletRemoteDataSource {
  final DioClient _dioClient;

  WalletRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> getWalletInfo() async {
    try {
      final response = await _dioClient.get('/wallet');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load wallet info: $e');
    }
  }

  Future<Map<String, dynamic>> getTransactions({int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        '/wallet/transactions',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }
}
