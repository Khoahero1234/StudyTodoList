// lib/features/inventory/screens/inventory_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Inventory', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: const Center(
        child: Text(
          '🎒 Inventory\ncoming in Phase 6',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
