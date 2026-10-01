// lib/features/shop/screens/shop_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Shop', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: const Center(
        child: Text(
          '🛍️ Shop\ncoming in Phase 6',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
