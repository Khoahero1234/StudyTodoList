// lib/features/shop/screens/product_detail_screen.dart

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

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  bool _isPurchasing = false;

  ProductModel _resolveCurrentProduct(ShopState shopState) {
    final idx =
        shopState.products.indexWhere((p) => p.id == widget.product.id);
    if (idx >= 0) {
      return shopState.products[idx];
    }
    return widget.product;
  }

  void _increment(ProductModel currentProduct) {
    final maxAllowed =
        currentProduct.isUnlimitedStock ? 99 : currentProduct.stock;
    if (_quantity < maxAllowed) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<void> _handlePurchase(
    ProductModel currentProduct,
    int currentBalance,
  ) async {
    final totalPrice = currentProduct.discountedPrice * _quantity;

    if (currentBalance < totalPrice) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Số dư Token không đủ! Bạn cần $totalPrice 🪙 nhưng hiện có $currentBalance 🪙.',
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
        title: Text('Xác nhận mua hàng', style: AppTextStyles.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc muốn mua vật phẩm này?',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Vật phẩm:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Flexible(
                        child: Text(
                          currentProduct.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số lượng:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        'x$_quantity',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số dư hiện tại:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        '$currentBalance 🪙',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Token sẽ trừ:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        '-$totalPrice 🪙',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số dư còn lại:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        '${currentBalance - totalPrice} 🪙',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Xác nhận mua'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isPurchasing = true);
    final success = await ref.read(shopProvider.notifier).purchaseItem(
          currentProduct.id,
          _quantity,
        );
    if (!mounted) return;
    setState(() => _isPurchasing = false);

    if (success) {
      final newBalance = ref.read(walletProvider).balance;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Mua thành công "${currentProduct.name}" (x$_quantity)! Đã trừ $totalPrice 🪙 (Còn lại: $newBalance 🪙).',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Kho đồ',
              textColor: Colors.white,
              onPressed: () => context.push(AppRoutes.inventory),
            ),
          ),
        );
      Navigator.pop(context);
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

    final currentProduct = _resolveCurrentProduct(shopState);
    final currentBalance = walletState.balance > 0
        ? walletState.balance
        : (user?.tokenBalance ?? 0);

    final totalPrice = currentProduct.discountedPrice * _quantity;
    final hasEnoughTokens = currentBalance >= totalPrice;
    final isOutOfStock = currentProduct.isOutOfStock;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(currentProduct.name, style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push(AppRoutes.wallet),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    const Text('🪙', style: TextStyle(fontSize: 14)),
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: currentProduct.imageUrl != null &&
                          currentProduct.imageUrl!.isNotEmpty
                      ? Image.network(
                          currentProduct.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.shopping_bag_rounded,
                            size: 80,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : const Icon(
                          Icons.shopping_bag_rounded,
                          size: 80,
                          color: AppColors.textSecondary,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    currentProduct.rarity.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (currentProduct.category != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Text(
                      currentProduct.category!.name,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  currentProduct.isUnlimitedStock
                      ? 'Kho: Không giới hạn'
                      : (isOutOfStock
                          ? 'Hết hàng'
                          : 'Kho còn: ${currentProduct.stock}'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isOutOfStock
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentProduct.name,
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${currentProduct.discountedPrice} 🪙',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                if (currentProduct.discountPct > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${currentProduct.price} 🪙',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '-${currentProduct.discountPct}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              currentProduct.description ??
                  'Chưa có mô tả chi tiết cho vật phẩm này.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Số lượng mua:',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _quantity > 1 ? _decrement : null,
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$_quantity',
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        onPressed: isOutOfStock
                            ? null
                            : () => _increment(currentProduct),
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số dư Token của bạn:',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '$currentBalance 🪙',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Số dư sau khi mua:',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        hasEnoughTokens
                            ? '${currentBalance - totalPrice} 🪙'
                            : 'Thiếu ${totalPrice - currentBalance} 🪙',
                        style: TextStyle(
                          color: hasEnoughTokens
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng thanh toán',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$totalPrice 🪙',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: (_isPurchasing || isOutOfStock)
                      ? null
                      : () => _handlePurchase(currentProduct, currentBalance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasEnoughTokens ? AppColors.primary : AppColors.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isPurchasing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isOutOfStock
                              ? Icons.remove_shopping_cart_rounded
                              : Icons.shopping_cart_checkout_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    isOutOfStock
                        ? 'Hết hàng'
                        : (_isPurchasing
                            ? 'Đang xử lý...'
                            : (hasEnoughTokens
                                ? 'Mua ngay (-$totalPrice 🪙)'
                                : 'Không đủ Token')),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
