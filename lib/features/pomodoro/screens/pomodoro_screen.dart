// lib/features/pomodoro/screens/pomodoro_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Pomodoro', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: const Center(
        child: Text(
          '⏱️ Pomodoro\ncoming in Phase 7',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
