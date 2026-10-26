// lib/features/pomodoro/screens/pomodoro_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../services/pomodoro_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int focusTime = 25 * 60; // 25 phút tập trung
  int _remainingSeconds = focusTime;
  bool _isRunning = false;
  Timer? _timer;
  String? _currentSessionId;

  // ID mẫu cho user (sau này lấy từ Auth provider của nhóm)
  final String _testUserId = "user-123";

  void _startTimer() async {
    if (!_isRunning) {
      // Gọi API báo backend khởi tạo phiên
      final sessionData = await PomodoroService.startSession(_testUserId);
      if (sessionData != null) {
        _currentSessionId = sessionData['id'].toString();
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
  }

  void _stopTimer({bool completed = false}) async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });

    if (completed && _currentSessionId != null) {
      // Gọi API hoàn thành session để lưu thống kê vào bảng ProductivityStatistic
      bool success = await PomodoroService.endSession(_currentSessionId!);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Hoàn thành phiên Pomodoro! Đã cộng XP và Token.'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Pomodoro Focus', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(50),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.indigoAccent, width: 4),
                color: Colors.grey.shade900,
              ),
              child: Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Bắt đầu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isRunning ? () => _stopTimer(completed: false) : null,
                  icon: const Icon(Icons.pause),
                  label: const Text('Tạm dừng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Đặt lại'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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