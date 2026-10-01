// lib/features/ai/screens/ai_chat_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('AI Assistant', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
      ),
      body: const Center(
        child: Text(
          '🤖 AI Assistant\ncoming in Phase 4',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
