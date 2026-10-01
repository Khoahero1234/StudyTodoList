// lib/features/premium/screens/premium_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Premium', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: const Center(
        child: Text(
          '⭐ Premium\ncoming in Phase 7',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
