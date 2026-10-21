// lib/features/shop/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/product_model.dart';
import '../providers/shop_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  bool _isPurchasing = false;

  void _increment() {
    if (_quantity < widget.product.stock) {
      setState(() => _quantity++);
    }
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  Future<void> _handlePurchase() async {
    setState(() => _isPurchasing = true);
    final success = await ref.read(shopProvider.notifier).purchaseItem(
          widget.product.id,
          _quantity,
        );
    setState(() => _isPurchasing = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase successful! Item added to inventory.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(shopProvider).errorMessage ?? 'Purchase failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.product.discountedPrice * _quantity;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(widget.product.name, style: AppTextStyles.titleMedium),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Center(
                child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                    ? Image.network(widget.product.imageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.shopping_bag_rounded, size: 80, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Text(
                    widget.product.rarity.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Stock available: ${widget.product.stock}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.product.name,
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${widget.product.discountedPrice} 🪙',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                if (widget.product.discountPct > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${widget.product.price}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.product.description ?? 'No description available for this item.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                const Text('Quantity:', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
                const Spacer(),
                IconButton(
                  onPressed: _decrement,
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.textPrimary),
                ),
                Text(
                  '$_quantity',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                ),
                IconButton(
                  onPressed: _increment,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.textPrimary),
                ),
              ],
            ),
            const Divider(color: AppColors.borderDark, height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Price', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text('$totalPrice 🪙', style: AppTextStyles.titleLarge.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton(
                  onPressed: (_isPurchasing || widget.product.stock <= 0) ? null : _handlePurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Buy Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
