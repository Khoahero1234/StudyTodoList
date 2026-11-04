// lib/features/pomodoro/screens/pomodoro_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../missions/providers/mission_provider.dart';
import '../../wallet/providers/wallet_provider.dart';
import '../services/pomodoro_service.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  static const int focusTime = 25 * 60; // 25 phút tập trung
  int _remainingSeconds = focusTime;
  bool _isRunning = false;
  bool _isSubmitting = false;
  Timer? _timer;
  String? _currentSessionId;

  Future<void> _startTimer() async {
    if (_isRunning) return;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null && userId.isNotEmpty) {
      final sessionData = await PomodoroService.startSession(userId);
      if (sessionData != null) {
        _currentSessionId = sessionData['id']?.toString();
      }
    }

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _stopTimer(completed: true);
      }
    });
  }

  Future<void> _stopTimer({bool completed = false}) async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });

    if (completed) {
      await _completeCurrentOrInstantSession();
    }
  }

  Future<void> _completeCurrentOrInstantSession() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final userId = ref.read(currentUserProvider)?.id;
      if (_currentSessionId == null && userId != null && userId.isNotEmpty) {
        final sessionData = await PomodoroService.startSession(userId);
        _currentSessionId = sessionData?['id']?.toString();
      }

      if (_currentSessionId != null) {
        final res = await PomodoroService.endSession(
          _currentSessionId!,
          xpEarned: 25,
          tokenEarned: 15,
        );
        _currentSessionId = null;

        await ref.read(walletProvider.notifier).refreshWallet();
        await ref.read(missionProvider.notifier).loadMissions(silent: true);
        ref.read(authProvider.notifier).refreshUser();

        if (mounted && res != null) {
          final missionEval =
              res['missionEvaluation'] as Map<String, dynamic>? ?? {};
          final bonusNow =
              (missionEval['totalTokensAwardedNow'] as num?)?.toInt() ?? 0;
          final totalTokens = 15 + bonusNow;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                bonusNow > 0
                    ? '🎉 Hoàn thành phiên Pomodoro (+15 🪙) & Mở khóa thưởng nhiệm vụ tự động (+$bonusNow 🪙)! Tổng +$totalTokens 🪙'
                    : '🎉 Hoàn thành phiên Pomodoro (25 phút)! Đã tự động cộng +15 🪙 vào ví.',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _remainingSeconds = focusTime;
        });
      }
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = focusTime;
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletBalance = ref.watch(walletProvider).balance;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Pomodoro Focus', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
        actions: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.wallet),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 5),
                  Text(
                    '$walletBalance',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 5),
                  color: AppColors.cardDark,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 28,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+15 🪙 / phiên hoàn thành',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isRunning ? null : _startTimer,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Bắt đầu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        _isRunning ? () => _stopTimer(completed: false) : null,
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Tạm dừng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Đặt lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
