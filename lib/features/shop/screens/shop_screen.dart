// lib/features/shop/screens/shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/wallet/providers/wallet_provider.dart';
import '../../../models/product_model.dart';
import '../providers/shop_provider.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(shopProvider.notifier).loadMoreProducts();
    }
  }

  Future<void> _handleQuickBuy(
    ProductModel product,
    int currentBalance,
  ) async {
    final price = product.discountedPrice;
    if (currentBalance < price) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Số dư Token không đủ! Cần $price 🪙 nhưng bạn hiện có $currentBalance 🪙.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Mua nhanh vật phẩm', style: AppTextStyles.titleMedium),
        content: Text(
          'Mua "${product.name}" (x1) với giá $price 🪙?\nSố dư sau khi mua: ${currentBalance - price} 🪙',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Mua (-$price 🪙)'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success =
        await ref.read(shopProvider.notifier).purchaseItem(product.id, 1);
    if (!mounted) return;

    if (success) {
      final newBalance = ref.read(walletProvider).balance;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Đã mua "${product.name}"! Trừ $price 🪙 (Số dư mới: $newBalance 🪙)',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Kho đồ',
              textColor: Colors.white,
              onPressed: () => context.push(AppRoutes.inventory),
            ),
          ),
        );
    } else {
      final error =
          ref.read(shopProvider).errorMessage ?? 'Mua hàng thất bại';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error, style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);
    final walletState = ref.watch(walletProvider);
    final user = ref.watch(currentUserProvider);

    final currentBalance = walletState.balance > 0
        ? walletState.balance
        : (user?.tokenBalance ?? 0);

    final totalOwnedItems = shopState.inventory.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Cửa hàng Vật phẩm', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          // Nút hiển thị Số dư Token (nhấn vào để mở Ví & Lịch sử giao dịch)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push(AppRoutes.wallet),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    '$currentBalance',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Nút mở Kho đồ & Lịch sử đơn hàng
          IconButton(
            tooltip: 'Kho vật phẩm & Đơn hàng',
            onPressed: () => context.push(AppRoutes.inventory),
            icon: Badge(
              isLabelVisible: totalOwnedItems > 0,
              label: Text('$totalOwnedItems'),
              child: const Icon(
                Icons.backpack_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm vật phẩm...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(shopProvider.notifier).setFilter(
                                    shopState.filter.copyWith(search: ''),
                                  );
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (value) {
                    final currentFilter = shopState.filter;
                    ref.read(shopProvider.notifier).setFilter(
                          currentFilter.copyWith(search: value.trim()),
                        );
                  },
                ),
                const SizedBox(height: 12),
                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: shopState.filter.categoryId == null,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(shopProvider.notifier).setFilter(
                                  shopState.filter
                                      .copyWith(clearCategory: true),
                                );
                          }
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceDark,
                        labelStyle: TextStyle(
                          color: shopState.filter.categoryId == null
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...shopState.categories.map((cat) {
                        final isSelected =
                            shopState.filter.categoryId == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              ref.read(shopProvider.notifier).setFilter(
                                    shopState.filter.copyWith(
                                      categoryId: selected ? cat.id : null,
                                      clearCategory: !selected,
                                    ),
                                  );
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceDark,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Product Grid
          Expanded(
            child: shopState.isLoading && shopState.products.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : shopState.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.storefront_outlined,
                              size: 56,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              shopState.errorMessage ??
                                  'Không tìm thấy sản phẩm nào',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () =>
                                  ref.read(shopProvider.notifier).initShop(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tải lại'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(shopProvider.notifier).initShop(),
                        color: AppColors.primary,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: shopState.products.length +
                              (shopState.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < shopState.products.length) {
                              final product = shopState.products[index];
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                                onQuickBuy: () =>
                                    _handleQuickBuy(product, currentBalance),
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              );
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
