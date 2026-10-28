// lib/features/pomodoro/screens/stats_screen.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../services/stats_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _weeklyData;
  final String _testUserId = "user-123"; // ID mẫu của user

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  void _fetchStats() async {
    setState(() {
      _isLoading = true;
    });

    final data = await StatsService.getWeeklyStats(_testUserId);

    setState(() {
      _weeklyData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = _weeklyData?['weeklySummary'];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Thống kê năng suất', style: AppTextStyles.titleLarge),
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔥 Tổng kết 7 ngày qua',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Phút tập trung',
                    '${summary?['totalFocusMinutes'] ?? 0} phút',
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Phiên Pomodoro',
                    '${summary?['totalPomodoroSessions'] ?? 0}',
                    Icons.task_alt,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'XP Nhận được',
                    '${summary?['totalXpEarned'] ?? 0} XP',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Token tích lũy',
                    '${summary?['totalTokensEarned'] ?? 0} 🪙',
                    Icons.monetization_on,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              '📊 Chi tiết theo ngày',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _weeklyData == null || (_weeklyData!['dailyStats'] as List).isEmpty
                  ? const Center(
                child: Text('Chưa có dữ liệu thống kê nào.', style: TextStyle(color: Colors.grey)),
              )
                  : ListView.builder(
                itemCount: (_weeklyData!['dailyStats'] as List).length,
                itemBuilder: (context, index) {
                  final item = _weeklyData!['dailyStats'][index];
                  String dateStr = item['date'].toString().substring(0, 10);
                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.indigoAccent),
                      title: Text('Ngày: $dateStr', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'Phút tập trung: ${item['focusMinutes']}m | Phiên: ${item['pomodoroSessions']}',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      trailing: Text(
                        '+${item['xpEarned']} XP',
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        // Đã thay thế withOpacity(0.5) bằng withValues(alpha: 0.5)
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}