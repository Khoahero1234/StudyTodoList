const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Lấy báo cáo năng suất hàng tuần (7 ngày gần nhất)
const getWeeklyStats = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({ success: false, message: 'Thiếu thông tin userId!' });
    }

    // Lấy ngày hiện tại và mốc 7 ngày trước
    const endDate = new Date();
    endDate.setHours(23, 59, 59, 999);

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - 6);
    startDate.setHours(0, 0, 0, 0);

    // Truy vấn dữ liệu thống kê trong khoảng thời gian từ bảng ProductivityStatistic
    const stats = await prisma.productivityStatistic.findMany({
      where: {
        userId: userId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: {
        date: 'asc',
      },
    });

    // Tính tổng hợp tổng số phút tập trung và tổng số task hoàn thành trong tuần
    const summary = stats.reduce(
      (acc, curr) => {
        acc.totalFocusMinutes += curr.focusMinutes;
        acc.totalPomodoroSessions += curr.pomodoroSessions;
        acc.totalTasksCompleted += curr.tasksCompleted;
        acc.totalXpEarned += curr.xpEarned;
        acc.totalTokensEarned += curr.tokensEarned;
        return acc;
      },
      {
        totalFocusMinutes: 0,
        totalPomodoroSessions: 0,
        totalTasksCompleted: 0,
        totalXpEarned: 0,
        totalTokensEarned: 0,
      }
    );

    return res.status(200).json({
      success: true,
      data: {
        dailyStats: stats,
        weeklySummary: summary,
      },
    });
  } catch (error) {
    console.error('Lỗi lấy weekly stats:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getWeeklyStats,
};