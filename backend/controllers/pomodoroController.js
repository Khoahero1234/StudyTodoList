const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// 1. Bắt đầu phiên Pomodoro mới
const startPomodoroSession = async (req, res) => {
  try {
    const { userId, taskId, focusMinutes, breakMinutes, sessionsPlanned } = req.body;

    if (!userId) {
      return res.status(400).json({ success: false, message: 'Thiếu thông tin userId!' });
    }

    const session = await prisma.pomodoroSession.create({
      data: {
        userId,
        taskId: taskId || null,
        focusMinutes: focusMinutes || 25,
        breakMinutes: breakMinutes || 5,
        sessionsPlanned: sessionsPlanned || 4,
        isCompleted: false,
      },
    });

    return res.status(201).json({
      success: true,
      message: 'Đã khởi tạo phiên Pomodoro thành công!',
      data: session,
    });
  } catch (error) {
    console.error('Lỗi start Pomodoro:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Kết thúc phiên Pomodoro và cập nhật thống kê ngày
const endPomodoroSession = async (req, res) => {
  try {
    const { sessionId, sessionsCompleted, xpEarned, tokenEarned } = req.body;

    if (!sessionId) {
      return res.status(400).json({ success: false, message: 'Thiếu sessionId!' });
    }

    // Cập nhật phiên pomodoro thành đã hoàn thành
    const updatedSession = await prisma.pomodoroSession.update({
      where: { id: sessionId },
      data: {
        sessionsCompleted: sessionsCompleted || 1,
        isCompleted: true,
        xpEarned: xpEarned || 10,
        tokenEarned: tokenEarned || 5,
        endedAt: new Date(),
      },
    });

    // Lấy ngày hiện tại (dạng chuẩn YYYY-MM-DD cho bảng ProductivityStatistic)
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Cập nhật hoặc tạo mới thống kê năng suất trong ngày của user
    await prisma.productivityStatistic.upsert({
      where: {
        userId_date: {
          userId: updatedSession.userId,
          date: today,
        },
      },
      update: {
        pomodoroSessions: { increment: 1 },
        focusMinutes: { increment: updatedSession.focusMinutes },
        xpEarned: { increment: updatedSession.xpEarned },
        tokensEarned: { increment: updatedSession.tokenEarned },
      },
      create: {
        userId: updatedSession.userId,
        date: today,
        pomodoroSessions: 1,
        focusMinutes: updatedSession.focusMinutes,
        xpEarned: updatedSession.xpEarned,
        tokensEarned: updatedSession.tokenEarned,
      },
    });

    return res.status(200).json({
      success: true,
      message: 'Đã hoàn thành phiên Pomodoro và cập nhật thống kê!',
      data: updatedSession,
    });
  } catch (error) {
    console.error('Lỗi end Pomodoro:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  startPomodoroSession,
  endPomodoroSession,
};