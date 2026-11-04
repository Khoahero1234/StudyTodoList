import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/product_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/admin_remote_data_source.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late final AdminRemoteDataSource _dataSource;
  List<Map<String, dynamic>> _users = [];
  List<ProductModel> _products = [];
  List<Map<String, dynamic>> _categories = [];
  int _userCount = 0;
  int _productCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dataSource = AdminRemoteDataSource(ref.read(dioClientProvider));
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _dataSource.getUsers(),
        _dataSource.getProducts(),
        _dataSource.getCategories(),
      ]);
      final usersResponse = results[0] as Map<String, dynamic>;
      final productsResponse = results[1] as Map<String, dynamic>;
      final users =
          (usersResponse['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      final products = (productsResponse['data'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _users = users;
        _products = products;
        _categories = results[2] as List<Map<String, dynamic>>;
        _userCount = usersResponse['total'] as int? ?? users.length;
        _productCount = productsResponse['total'] as int? ?? products.length;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) return;
      _showMessage(successMessage);
      await _loadData();
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.error : AppColors.success,
        ),
      );
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin dashboard', style: AppTextStyles.titleLarge),
              Text(
                user?.email ?? '',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Tải lại dữ liệu',
              onPressed: _isLoading ? null : _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Đăng xuất',
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Sản phẩm'),
              Tab(icon: Icon(Icons.category_outlined), text: 'Danh mục'),
              Tab(icon: Icon(Icons.people_outline), text: 'Tài khoản'),
            ],
          ),
        ),
        body: _isLoading && _users.isEmpty && _products.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorMessage != null && _users.isEmpty && _products.isEmpty
                ? _LoadError(message: _errorMessage!, onRetry: _loadData)
                : Column(
                    children: [
                      if (_errorMessage != null)
                        MaterialBanner(
                          content: Text(_errorMessage!),
                          leading: const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          backgroundColor: AppColors.cardDark,
                          actions: [
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      _SummaryRow(
                        users: _userCount,
                        products: _productCount,
                        categories: _categories.length,
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProductsTab(),
                            _buildCategoriesTab(),
                            _buildUsersTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CreateButton(
            label: 'Thêm sản phẩm',
            onPressed: () => _editProduct(),
          ),
          if (_products.isEmpty)
            const _EmptyState(message: 'Chưa có sản phẩm nào.')
          else
            ..._products.map(
              (product) => _AdminCard(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: product.name,
                subtitle:
                    '${product.price} token · ${product.category?.name ?? 'Chưa có danh mục'} · Kho: ${product.stock < 0 ? 'Không giới hạn' : product.stock}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Sửa sản phẩm',
                      onPressed: () => _editProduct(product),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Xóa sản phẩm',
                      onPressed: () => _deleteProduct(product),
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                    ),
                  ],
                ),
                badge: product.isAvailable ? 'Đang bán' : 'Đã ẩn',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _CreateButton(
            label: 'Thêm danh mục',
            onPressed: () => _editCategory(),
          ),
          if (_categories.isEmpty)
            const _EmptyState(message: 'Chưa có danh mục nào.')
          else
            ..._categories.map(
              (category) => _AdminCard(
                leading: const Icon(Icons.folder_outlined),
                title: category['name'] as String? ?? 'Danh mục',
                subtitle: category['description'] as String? ?? '',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Sửa danh mục',
                      onPressed: () => _editCategory(category),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Xóa danh mục',
                      onPressed: () => _deleteCategory(category),
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                    ),
                  ],
                ),
                badge: '${(category['_count'] as Map?)?['products'] ?? 0} SP',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_users.isEmpty)
            const _EmptyState(message: 'Chưa có tài khoản nào.')
          else
            ..._users.map((user) {
              final id = user['id'] as String? ?? '';
              final role = user['role'] as String? ?? 'CUSTOMER';
              final isActive = user['isActive'] as bool? ?? true;
              final username = user['displayName'] as String? ??
                  user['username'] as String? ??
                  'Người dùng';
              final isCurrentUser = id == currentUserId;
              return _AdminCard(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child:
                      Text(username.isEmpty ? 'U' : username[0].toUpperCase()),
                ),
                title: username,
                subtitle: user['email'] as String? ?? '',
                badge: role == 'ADMIN' ? 'ADMIN' : 'CUSTOMER',
                trailing: PopupMenuButton<String>(
                  tooltip: 'Quản lý tài khoản',
                  onSelected: (action) => _manageUser(
                    user,
                    action,
                    isCurrentUser: isCurrentUser,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'role',
                      enabled: !isCurrentUser,
                      child: Text(
                        role == 'ADMIN'
                            ? 'Chuyển thành customer'
                            : 'Cấp quyền admin',
                      ),
                    ),
                    PopupMenuItem(
                      value: 'ban',
                      enabled: !isCurrentUser,
                      child: Text(
                          isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.more_vert),
                  ),
                ),
                footer: Text(
                  isActive ? 'Đang hoạt động' : 'Đã khóa',
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontSize: 12,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _manageUser(
    Map<String, dynamic> user,
    String action, {
    required bool isCurrentUser,
  }) async {
    if (isCurrentUser) return;
    final id = user['id'] as String? ?? '';
    if (action == 'role') {
      final currentRole = user['role'] as String? ?? 'CUSTOMER';
      final newRole = currentRole == 'ADMIN' ? 'CUSTOMER' : 'ADMIN';
      if (!await _confirm(
        'Thay đổi vai trò',
        'Đổi tài khoản này thành $newRole?',
      )) {
        return;
      }
      await _runAction(
        () => _dataSource.changeUserRole(id, newRole),
        'Đã cập nhật vai trò tài khoản.',
      );
    } else {
      final isActive = user['isActive'] as bool? ?? true;
      if (!await _confirm(
        isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
        'Bạn có chắc muốn ${isActive ? 'khóa' : 'mở khóa'} tài khoản này?',
      )) {
        return;
      }
      await _runAction(
        () => _dataSource.toggleUserBan(id),
        isActive ? 'Đã khóa tài khoản.' : 'Đã mở khóa tài khoản.',
      );
    }
  }

  Future<void> _editProduct([ProductModel? product]) async {
    if (_categories.isEmpty) {
      _showMessage('Hãy tạo danh mục trước khi thêm sản phẩm.', isError: true);
      return;
    }
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController =
        TextEditingController(text: product?.description ?? '');
    final imageController =
        TextEditingController(text: product?.imageUrl ?? '');
    final priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    final stockController =
        TextEditingController(text: product?.stock.toString() ?? '-1');
    final discountController =
        TextEditingController(text: product?.discountPct.toString() ?? '0');
    var categoryId = product?.categoryId ?? _categories.first['id'] as String;
    var rarity = product?.rarity.toUpperCase() ?? 'COMMON';
    var isAvailable = product?.isAvailable ?? true;
    var isPremiumOnly = product?.premiumOnly ?? false;
    String? formError;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _formField(nameController, 'Tên sản phẩm',
                        validator: _requiredValidator),
                    _formField(descriptionController, 'Mô tả'),
                    _formField(imageController, 'URL hình ảnh'),
                    _formField(
                      priceController,
                      'Giá (token)',
                      number: true,
                      validator: _nonNegativeValidator,
                    ),
                    _formField(
                      stockController,
                      'Tồn kho (-1 = không giới hạn)',
                      number: true,
                      validator: _stockValidator,
                    ),
                    _formField(
                      discountController,
                      'Giảm giá (%)',
                      number: true,
                      validator: _discountValidator,
                    ),
                    DropdownButtonFormField<String>(
                      value: categoryId,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      items: _categories
                          .map((category) => DropdownMenuItem(
                                value: category['id'] as String,
                                child: Text(category['name'] as String),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => categoryId = value);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      value: rarity,
                      decoration: const InputDecoration(labelText: 'Độ hiếm'),
                      items: const [
                        'COMMON',
                        'UNCOMMON',
                        'RARE',
                        'EPIC',
                        'LEGENDARY',
                      ]
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setDialogState(() => rarity = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đang mở bán'),
                      value: isAvailable,
                      onChanged: (value) =>
                          setDialogState(() => isAvailable = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Chỉ dành cho Premium'),
                      value: isPremiumOnly,
                      onChanged: (value) =>
                          setDialogState(() => isPremiumOnly = value),
                    ),
                    if (formError != null)
                      Text(formError!,
                          style: const TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final data = {
                  'name': nameController.text.trim(),
                  'description': _nullable(descriptionController.text),
                  'imageUrl': _nullable(imageController.text),
                  'price': int.parse(priceController.text),
                  'stock': int.parse(stockController.text),
                  'discountPct': int.parse(discountController.text),
                  'categoryId': categoryId,
                  'rarity': rarity,
                  'isAvailable': isAvailable,
                  'isPremiumOnly': isPremiumOnly,
                };
                try {
                  if (product == null) {
                    await _dataSource.createProduct(data);
                  } else {
                    await _dataSource.updateProduct(product.id, data);
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (error) {
                  setDialogState(() => formError = error.toString());
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
    imageController.dispose();
    priceController.dispose();
    stockController.dispose();
    discountController.dispose();
    if (saved == true && mounted) {
      await _runAction(
        () async {},
        product == null ? 'Đã thêm sản phẩm.' : 'Đã cập nhật sản phẩm.',
      );
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    if (!await _confirm(
      'Xóa sản phẩm',
      'Xóa "${product.name}" khỏi shop?',
    )) {
      return;
    }
    await _runAction(
      () => _dataSource.deleteProduct(product.id),
      'Đã xóa sản phẩm.',
    );
  }

  Future<void> _editCategory([Map<String, dynamic>? category]) async {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: category?['name'] as String? ?? '');
    final descriptionController =
        TextEditingController(text: category?['description'] as String? ?? '');
    final iconController =
        TextEditingController(text: category?['iconUrl'] as String? ?? '');
    String? formError;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Thêm danh mục' : 'Sửa danh mục'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _formField(nameController, 'Tên danh mục',
                    validator: _requiredValidator),
                _formField(descriptionController, 'Mô tả'),
                _formField(iconController, 'URL biểu tượng'),
                if (formError != null)
                  Text(formError!,
                      style: const TextStyle(color: AppColors.error)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final data = {
                  'name': nameController.text.trim(),
                  'description': _nullable(descriptionController.text),
                  'iconUrl': _nullable(iconController.text),
                };
                try {
                  final id = category?['id'] as String?;
                  if (id == null) {
                    await _dataSource.createCategory(data);
                  } else {
                    await _dataSource.updateCategory(id, data);
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                } catch (error) {
                  setDialogState(() => formError = error.toString());
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    descriptionController.dispose();
    iconController.dispose();
    if (saved == true && mounted) {
      await _runAction(
        () async {},
        category == null ? 'Đã thêm danh mục.' : 'Đã cập nhật danh mục.',
      );
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final name = category['name'] as String? ?? 'danh mục này';
    if (!await _confirm('Xóa danh mục', 'Xóa "$name"?')) return;
    await _runAction(
      () => _dataSource.deleteCategory(category['id'] as String),
      'Đã xóa danh mục.',
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty
        ? 'Trường này là bắt buộc'
        : null;
  }

  String? _nonNegativeValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 1 ? 'Giá phải lớn hơn 0' : null;
  }

  String? _stockValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < -1 ? 'Tồn kho phải từ -1 trở lên' : null;
  }

  String? _discountValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    return parsed == null || parsed < 0 || parsed > 100
        ? 'Giảm giá phải từ 0 đến 100'
        : null;
  }

  String? _nullable(String value) => value.trim().isEmpty ? null : value.trim();
}

class _SummaryRow extends StatelessWidget {
  final int users;
  final int products;
  final int categories;

  const _SummaryRow({
    required this.users,
    required this.products,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          _SummaryCard(label: 'Tài khoản', value: users, icon: Icons.people),
          _SummaryCard(
            label: 'Sản phẩm',
            value: products,
            icon: Icons.shopping_bag,
          ),
          _SummaryCard(
            label: 'Danh mục',
            value: categories,
            icon: Icons.category,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: AppColors.cardDark,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryLight),
              const SizedBox(height: 4),
              Text('$value', style: AppTextStyles.titleLarge),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String? badge;
  final Widget? trailing;
  final Widget? footer;

  const _AdminCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.badge,
    this.trailing,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (badge != null || footer != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (footer != null) footer!,
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _CreateButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppButton(
        label: label,
        onPressed: onPressed,
        prefixIcon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Không tải được dữ liệu quản trị.\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
