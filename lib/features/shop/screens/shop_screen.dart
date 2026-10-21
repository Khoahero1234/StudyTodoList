// lib/features/shop/screens/shop_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
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

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shopProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Shop & Rewards', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filters bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderDark),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderDark),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onSubmitted: (value) {
                    final currentFilter = shopState.filter;
                    ref.read(shopProvider.notifier).setFilter(
                          currentFilter.copyWith(search: value),
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
                        label: const Text('All Categories'),
                        selected: shopState.filter.categoryId == null,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(shopProvider.notifier).setFilter(
                                  shopState.filter.copyWith(clearCategory: true),
                                );
                          }
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surfaceDark,
                        labelStyle: TextStyle(
                          color: shopState.filter.categoryId == null ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...shopState.categories.map((cat) {
                        final isSelected = shopState.filter.categoryId == cat.id;
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
                              color: isSelected ? Colors.white : AppColors.textSecondary,
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
                        child: Text(
                          'No products found',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(shopProvider.notifier).initShop(),
                        color: AppColors.primary,
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: shopState.products.length + (shopState.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < shopState.products.length) {
                              final product = shopState.products[index];
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
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
