// lib/features/shop/data/shop_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/product_model.dart';

class ShopRemoteDataSource {
  final DioClient _dioClient;

  ShopRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? categoryId,
    String? rarity,
    bool? premiumOnly,
  }) async {
    final Map<String, dynamic> query = {
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (categoryId != null && categoryId.isNotEmpty) query['categoryId'] = categoryId;
    if (rarity != null && rarity.isNotEmpty) query['rarity'] = rarity;
    if (premiumOnly != null) query['premiumOnly'] = premiumOnly;

    try {
      final response = await _dioClient.get(
        '/shop/products',
        queryParameters: query,
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _dioClient.get('/shop/products/$id');
      return ProductModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get product details: $e');
    }
  }

  Future<List<ProductCategoryModel>> getCategories() async {
    try {
      final response = await _dioClient.get('/shop/categories');
      final list = response.data['data'] as List<dynamic>? ?? [];
      return list.map((e) => ProductCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<void> purchaseItem(String productId, int quantity) async {
    try {
      await _dioClient.post(
        '/orders',
        data: {
          'items': [
            {'productId': productId, 'quantity': quantity}
          ]
        },
      );
    } catch (e) {
      throw Exception('Failed to purchase item: $e');
    }
  }
}
