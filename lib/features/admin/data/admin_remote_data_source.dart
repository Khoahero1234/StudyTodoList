import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class AdminRemoteDataSource {
  final DioClient _dioClient;

  const AdminRemoteDataSource(this._dioClient);

  Future<Map<String, dynamic>> getUsers() async {
    final response = await _dioClient.get(
      ApiEndpoints.adminUsers,
      queryParameters: {'page': 1, 'limit': 100},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProducts() async {
    final response = await _dioClient.get(
      ApiEndpoints.adminProducts,
      queryParameters: {'page': 1, 'limit': 100},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _dioClient.get(ApiEndpoints.adminCategories);
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> changeUserRole(String id, String role) async {
    await _dioClient.patch(
      ApiEndpoints.adminUserRole(id),
      data: {'role': role},
    );
  }

  Future<void> toggleUserBan(String id) async {
    await _dioClient.patch(ApiEndpoints.adminUserStatus(id));
  }

  Future<void> createProduct(Map<String, dynamic> data) async {
    await _dioClient.post(ApiEndpoints.adminProducts, data: data);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _dioClient.put(ApiEndpoints.adminProductById(id), data: data);
  }

  Future<void> deleteProduct(String id) async {
    await _dioClient.delete(ApiEndpoints.adminProductById(id));
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    await _dioClient.post(ApiEndpoints.adminCategories, data: data);
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _dioClient.put(ApiEndpoints.adminCategoryById(id), data: data);
  }

  Future<void> deleteCategory(String id) async {
    await _dioClient.delete(ApiEndpoints.adminCategoryById(id));
  }
}
