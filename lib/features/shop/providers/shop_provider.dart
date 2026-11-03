// lib/features/shop/providers/shop_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/product_model.dart';
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
  final ShopFilter filter;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  const ShopState({
    this.products = const [],
    this.categories = const [],
    this.filter = const ShopFilter(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasMore = false,
  });

  ShopState copyWith({
    List<ProductModel>? products,
    List<ProductCategoryModel>? categories,
    ShopFilter? filter,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
    bool clearError = false,
  }) {
    return ShopState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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

  Future<void> initShop() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _remoteDataSource.getCategories();
      await fetchProducts(page: 1, filter: state.filter, categories: categories);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchProducts({required int page, required ShopFilter filter, List<ProductCategoryModel>? categories}) async {
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
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> setFilter(ShopFilter newFilter) async {
    state = state.copyWith(isLoading: true, filter: newFilter);
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
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  Future<bool> purchaseItem(String productId, int quantity) async {
    try {
      await _remoteDataSource.purchaseItem(productId, quantity);
      
      // Refresh wallet from Module 1 and user info
      _ref.read(walletProvider.notifier).refreshWallet();
      _ref.read(authProvider.notifier).refreshUser();
      
      // Refresh product stock list
      await fetchProducts(page: 1, filter: state.filter);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

final shopProvider = StateNotifierProvider<ShopNotifier, ShopState>((ref) {
  final remoteDataSource = ref.watch(shopRemoteDataSourceProvider);
  return ShopNotifier(remoteDataSource, ref);
});
