// lib/features/shop/providers/shop_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/product_model.dart';
import '../../../models/token_transaction_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../data/shop_remote_datasource.dart';

final shopRemoteDataSourceProvider = Provider<ShopRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ShopRemoteDataSource(dioClient);
});

class ShopFilter {
  final String search;
  final String? categoryId;
  final String? rarity;
  final bool? premiumOnly;

  const ShopFilter({
    this.search = '',
    this.categoryId,
    this.rarity,
    this.premiumOnly,
  });

  ShopFilter copyWith({
    String? search,
    String? categoryId,
    String? rarity,
    bool? premiumOnly,
    bool clearCategory = false,
    bool clearRarity = false,
    bool clearPremium = false,
  }) {
    return ShopFilter(
      search: search ?? this.search,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      rarity: clearRarity ? null : (rarity ?? this.rarity),
      premiumOnly: clearPremium ? null : (premiumOnly ?? this.premiumOnly),
    );
  }
}

class ShopState {
  final List<ProductModel> products;
  final List<ProductCategoryModel> categories;
  final List<InventoryItemModel> inventory;
  final List<OrderModel> orders;
  final ShopFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isLoadingInventory;
  final String? errorMessage;
  final String? lastPurchaseMessage;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const ShopState({
    this.products = const [],
    this.categories = const [],
    this.inventory = const [],
    this.orders = const [],
    this.filter = const ShopFilter(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isLoadingInventory = false,
    this.errorMessage,
    this.lastPurchaseMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  ShopState copyWith({
    List<ProductModel>? products,
    List<ProductCategoryModel>? categories,
    List<InventoryItemModel>? inventory,
    List<OrderModel>? orders,
    ShopFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isLoadingInventory,
    String? errorMessage,
    String? lastPurchaseMessage,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool clearError = false,
    bool clearPurchaseMessage = false,
  }) {
    return ShopState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      inventory: inventory ?? this.inventory,
      orders: orders ?? this.orders,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isLoadingInventory: isLoadingInventory ?? this.isLoadingInventory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastPurchaseMessage: clearPurchaseMessage
          ? null
          : (lastPurchaseMessage ?? this.lastPurchaseMessage),
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ShopNotifier extends StateNotifier<ShopState> {
  final ShopRemoteDataSource _remoteDataSource;
  final Ref _ref;

  ShopNotifier(this._remoteDataSource, this._ref) : super(const ShopState()) {
    initShop();
  }

  String _cleanError(Object e) {
    final s = e.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }

  Future<void> initShop() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Đảm bảo dữ liệu ví được tải mới nhất khi vào Shop
      _ref.read(walletProvider.notifier).refreshWallet();

      final categories = await _remoteDataSource.getCategories();
      await fetchProducts(
          page: 1, filter: state.filter, categories: categories);
      fetchInventoryAndOrders();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _cleanError(e));
    }
  }

  Future<void> fetchProducts({
    required int page,
    required ShopFilter filter,
    List<ProductCategoryModel>? categories,
  }) async {
    try {
      final data = await _remoteDataSource.getProducts(
        page: page,
        limit: 20,
        search: filter.search,
        categoryId: filter.categoryId,
        rarity: filter.rarity,
        premiumOnly: filter.premiumOnly,
      );

      final rawList = data['products'] as List<dynamic>? ?? [];
      final products = rawList
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final currentPage = pagination['page'] as int? ?? page;
      final totalPages = pagination['totalPages'] as int? ?? 1;

      state = state.copyWith(
        products: products,
        categories: categories ?? state.categories,
        filter: filter,
        isLoading: false,
        currentPage: currentPage,
        totalPages: totalPages,
        hasMore: currentPage < totalPages,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _cleanError(e));
    }
  }

  Future<void> fetchInventoryAndOrders() async {
    state = state.copyWith(isLoadingInventory: true);
    try {
      final invFuture = _remoteDataSource.getInventory().catchError((e) {
        debugPrint('[ShopProvider] Lỗi khi tải Inventory: $e');
        return <InventoryItemModel>[];
      });
      final ordersFuture =
          _remoteDataSource.getOrders(page: 1, limit: 30).catchError((e) {
        debugPrint('[ShopProvider] Lỗi khi tải Orders: $e');
        return <OrderModel>[];
      });

      final results = await Future.wait([invFuture, ordersFuture]);
      state = state.copyWith(
        inventory: results[0] as List<InventoryItemModel>,
        orders: results[1] as List<OrderModel>,
        isLoadingInventory: false,
      );
    } catch (e) {
      debugPrint('[ShopProvider] Lỗi tổng hợp fetchInventoryAndOrders: $e');
      state = state.copyWith(isLoadingInventory: false);
    }
  }

  Future<bool> toggleEquipItem(String inventoryItemId) async {
    try {
      final updated = await _remoteDataSource.toggleEquipItem(inventoryItemId);
      final updatedList = state.inventory
          .map((item) => item.id == inventoryItemId ? updated : item)
          .toList();
      state = state.copyWith(inventory: updatedList, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _cleanError(e));
      return false;
    }
  }

  Future<void> setFilter(ShopFilter newFilter) async {
    state = state.copyWith(isLoading: true, filter: newFilter, clearError: true);
    await fetchProducts(page: 1, filter: newFilter);
  }

  Future<void> loadMoreProducts() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final data = await _remoteDataSource.getProducts(
        page: nextPage,
        limit: 20,
        search: state.filter.search,
        categoryId: state.filter.categoryId,
        rarity: state.filter.rarity,
        premiumOnly: state.filter.premiumOnly,
      );

      final rawList = data['products'] as List<dynamic>? ?? [];
      final newProducts = rawList
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
      final totalPages = pagination['totalPages'] as int? ?? state.totalPages;

      state = state.copyWith(
        products: [...state.products, ...newProducts],
        isLoadingMore: false,
        currentPage: nextPage,
        totalPages: totalPages,
        hasMore: nextPage < totalPages,
      );
    } catch (e) {
      state = state.copyWith(
          isLoadingMore: false, errorMessage: _cleanError(e));
    }
  }

  /// Mua vật phẩm trong Shop và trừ Token
  Future<bool> purchaseItem(String productId, int quantity) async {
    state = state.copyWith(clearError: true, clearPurchaseMessage: true);

    if (quantity <= 0) {
      state = state.copyWith(errorMessage: 'Số lượng mua phải lớn hơn 0');
      return false;
    }

    // Tìm thông tin sản phẩm trong state để kiểm tra nhanh số dư và tồn kho
    final productIndex = state.products.indexWhere((p) => p.id == productId);
    final product = productIndex >= 0 ? state.products[productIndex] : null;

    if (product != null) {
      if (product.isOutOfStock) {
        state = state.copyWith(
            errorMessage: 'Sản phẩm "${product.name}" hiện đã hết hàng');
        return false;
      }
      if (!product.isUnlimitedStock && product.stock < quantity) {
        state = state.copyWith(
            errorMessage:
                'Sản phẩm "${product.name}" chỉ còn ${product.stock} cái trong kho');
        return false;
      }

      final totalCost = product.discountedPrice * quantity;
      final walletState = _ref.read(walletProvider);
      final userBalance = _ref.read(currentUserProvider)?.tokenBalance ?? 0;
      final currentBalance =
          walletState.balance > 0 ? walletState.balance : userBalance;

      if (currentBalance < totalCost) {
        state = state.copyWith(
          errorMessage:
              'Số dư Token không đủ! Cần $totalCost 🪙 nhưng bạn hiện có $currentBalance 🪙.',
        );
        return false;
      }
    }

    try {
      if (kUseMock && product != null) {
        final totalCost = product.discountedPrice * quantity;
        _ref.read(walletProvider.notifier).recordPurchaseDeduction(
              deductedTokens: totalCost,
              itemSummary: '${product.name} (x$quantity)',
            );
        if (!product.isUnlimitedStock) {
          final updatedProducts = [...state.products];
          updatedProducts[productIndex] =
              product.copyWith(stock: product.stock - quantity);
          state = state.copyWith(
            products: updatedProducts,
            lastPurchaseMessage:
                'Mua thành công ${product.name} (x$quantity)! Đã trừ $totalCost 🪙.',
          );
        }
        return true;
      }

      final result = await _remoteDataSource.purchaseItem(productId, quantity);

      final deductedTokens = (result['deductedTokens'] as num?)?.toInt() ??
          (product != null ? product.discountedPrice * quantity : 0);
      final updatedServerBalance = (result['walletBalance'] as num?)?.toInt();

      TokenTransactionModel? serverTx;
      if (result['transaction'] is Map<String, dynamic>) {
        serverTx = TokenTransactionModel.fromJson(
            result['transaction'] as Map<String, dynamic>);
      }

      final itemName = product?.name ?? 'Vật phẩm';

      // 1. Trừ Token ngay lập tức trong WalletProvider và AuthProvider
      _ref.read(walletProvider.notifier).recordPurchaseDeduction(
            deductedTokens: deductedTokens,
            itemSummary: '$itemName (x$quantity)',
            updatedServerBalance: updatedServerBalance,
            serverTransaction: serverTx,
          );

      // 2. Cập nhật tồn kho sản phẩm ngay lập tức trên UI nếu có giới hạn tồn kho
      if (product != null && !product.isUnlimitedStock && productIndex >= 0) {
        final updatedProducts = [...state.products];
        updatedProducts[productIndex] = product.copyWith(
          stock: (product.stock - quantity).clamp(0, 999999),
        );
        state = state.copyWith(products: updatedProducts);
      }

      state = state.copyWith(
        lastPurchaseMessage:
            'Mua thành công $itemName (x$quantity)! Đã trừ $deductedTokens 🪙.',
      );

      // Cập nhật nhanh kho đồ từ server response nếu có
      if (result['inventoryItems'] is List) {
        final serverInv = (result['inventoryItems'] as List)
            .map((e) => e is Map
                ? InventoryItemModel.fromJson(Map<String, dynamic>.from(e))
                : null)
            .whereType<InventoryItemModel>()
            .toList();
        if (serverInv.isNotEmpty) {
          state = state.copyWith(inventory: serverInv);
        }
      }

      // 3. Đồng bộ lại dữ liệu chuẩn từ Server (Ví, User, Danh sách sản phẩm, Kho đồ & Đơn hàng)
      _ref.read(walletProvider.notifier).refreshWallet();
      _ref.read(authProvider.notifier).refreshUser();
      await fetchProducts(page: 1, filter: state.filter);
      fetchInventoryAndOrders();

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _cleanError(e));
      return false;
    }
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  final remoteDataSource = ref.watch(shopRemoteDataSourceProvider);
  return ShopNotifier(remoteDataSource, ref);
});
