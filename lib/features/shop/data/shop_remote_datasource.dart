// lib/features/shop/data/shop_remote_datasource.dart

import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/product_model.dart';

class ShopRemoteDataSource {
  final DioClient _dioClient;

  ShopRemoteDataSource(this._dioClient);

  String _extractErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'] ?? data['error'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }
    final raw = error.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : fallback;
  }

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
    if (categoryId != null && categoryId.isNotEmpty) {
      query['categoryId'] = categoryId;
    }
    if (rarity != null && rarity.isNotEmpty) query['rarity'] = rarity;
    if (premiumOnly != null) query['premiumOnly'] = premiumOnly;

    try {
      final response = await _dioClient.get(
        '/shop/products',
        queryParameters: query,
      );
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải danh sách sản phẩm'));
    }
  }

  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await _dioClient.get('/shop/products/$id');
      return ProductModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải chi tiết sản phẩm'));
    }
  }

  Future<List<ProductCategoryModel>> getCategories() async {
    try {
      final response = await _dioClient.get('/shop/categories');
      final list = response.data['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => ProductCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải danh mục sản phẩm'));
    }
  }

  Future<Map<String, dynamic>> purchaseItem(
      String productId, int quantity) async {
    try {
      final response = await _dioClient.post(
        '/orders',
        data: {
          'items': [
            {'productId': productId, 'quantity': quantity}
          ]
        },
      );
      final body = response.data;
      if (body is Map<String, dynamic>) {
        return (body['data'] as Map<String, dynamic>?) ?? body;
      }
      return <String, dynamic>{};
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Mua hàng thất bại'));
    }
  }

  Future<List<InventoryItemModel>> getInventory() async {
    try {
      final response = await _dioClient.get('/orders/inventory');
      final rawData = response.data;
      dynamic data = rawData;
      if (rawData is Map) {
        data = rawData['data'] ?? rawData;
      }
      List<dynamic> list = [];
      if (data is Map) {
        final rawItems = data['items'] ?? data['inventory'];
        if (rawItems is List) {
          list = rawItems;
        }
      } else if (data is List) {
        list = data;
      }
      return list.map((e) {
        if (e is Map<String, dynamic>) {
          return InventoryItemModel.fromJson(e);
        } else if (e is Map) {
          return InventoryItemModel.fromJson(Map<String, dynamic>.from(e));
        }
        return InventoryItemModel.fromJson({});
      }).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải kho vật phẩm'));
    }
  }

  Future<InventoryItemModel> toggleEquipItem(String inventoryItemId) async {
    try {
      final response =
          await _dioClient.patch('/orders/inventory/$inventoryItemId/equip');
      final rawData = response.data;
      dynamic data = rawData;
      if (rawData is Map) {
        data = rawData['data'] ?? rawData;
      }
      if (data is Map<String, dynamic>) {
        return InventoryItemModel.fromJson(data);
      } else if (data is Map) {
        return InventoryItemModel.fromJson(Map<String, dynamic>.from(data));
      }
      return InventoryItemModel.fromJson({});
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể cập nhật trạng thái trang bị'));
    }
  }

  Future<List<OrderModel>> getOrders({int page = 1, int limit = 20}) async {
    try {
      final response = await _dioClient.get(
        '/orders',
        queryParameters: {'page': page, 'limit': limit},
      );
      final rawData = response.data;
      dynamic data = rawData;
      if (rawData is Map) {
        data = rawData['data'] ?? rawData;
      }
      List<dynamic> list = [];
      if (data is Map) {
        final rawOrders = data['orders'] ?? data['items'];
        if (rawOrders is List) {
          list = rawOrders;
        }
      } else if (data is List) {
        list = data;
      }
      return list.map((e) {
        if (e is Map<String, dynamic>) {
          return OrderModel.fromJson(e);
        } else if (e is Map) {
          return OrderModel.fromJson(Map<String, dynamic>.from(e));
        }
        return OrderModel.fromJson({});
      }).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e, 'Không thể tải lịch sử đơn hàng'));
    }
  }
}
