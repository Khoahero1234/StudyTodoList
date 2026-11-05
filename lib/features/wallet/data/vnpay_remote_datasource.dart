// lib/features/wallet/data/vnpay_remote_datasource.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/token_package_model.dart';
import '../../auth/providers/auth_provider.dart';

final vnpayRemoteDataSourceProvider = Provider<VNPayRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return VNPayRemoteDataSource(dioClient);
});

class VNPayRemoteDataSource {
  final DioClient _dioClient;

  VNPayRemoteDataSource(this._dioClient);

  /// Lấy danh sách các gói nạp Token
  Future<List<TokenPackageModel>> getPackages() async {
    try {
      final response = await _dioClient.get('/vnpay/packages');
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] as List<dynamic>? ?? [];
        return list
            .map((item) => TokenPackageModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      // Fallback danh sách mặc định nếu server tạm thời chưa phản hồi
      return const [
        TokenPackageModel(id: 'pkg_10k', amount: 10000, tokens: 100, label: 'Gói Đồng (100 🪙)', bonusPercent: 0),
        TokenPackageModel(id: 'pkg_20k', amount: 20000, tokens: 220, label: 'Gói Bạc (220 🪙)', bonusPercent: 10),
        TokenPackageModel(id: 'pkg_50k', amount: 50000, tokens: 600, label: 'Gói Vàng (600 🪙)', bonusPercent: 20),
        TokenPackageModel(id: 'pkg_100k', amount: 100000, tokens: 1300, label: 'Gói Kim Cương (1,300 🪙)', bonusPercent: 30),
        TokenPackageModel(id: 'pkg_200k', amount: 200000, tokens: 2800, label: 'Gói Huyền Thoại (2,800 🪙)', bonusPercent: 40),
        TokenPackageModel(id: 'pkg_500k', amount: 500000, tokens: 7500, label: 'Gói Đại Gia (7,500 🪙)', bonusPercent: 50),
      ];
    }
  }

  /// Tạo link thanh toán VNPay
  Future<String> createPaymentUrl({
    required String packageId,
    required int amount,
    required int tokens,
    String? bankCode,
  }) async {
    final response = await _dioClient.post(
      '/vnpay/create-payment-url',
      data: {
        'packageId': packageId,
        'amount': amount,
        'tokens': tokens,
        if (bankCode != null && bankCode.isNotEmpty) 'bankCode': bankCode,
      },
    );

    if (response.data != null && response.data['success'] == true) {
      return response.data['data']['paymentUrl'] as String;
    } else {
      throw Exception(response.data?['message'] ?? 'Không thể tạo liên kết thanh toán VNPay');
    }
  }

  /// Xác thực kết quả thanh toán VNPay với Backend server để cộng Tokens vào ví
  Future<Map<String, dynamic>> confirmPaymentReturn(Map<String, String> queryParameters) async {
    try {
      final response = await _dioClient.get(
        '/vnpay/vnpay-return',
        queryParameters: {
          ...queryParameters,
          'format': 'json',
        },
      );
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>? ?? {};
      }
      return {};
    } catch (e) {
      print('[VNPayDataSource] confirmPaymentReturn error: $e');
      rethrow;
    }
  }
}
