const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const walletService = require('../services/walletService');
const petService = require('../services/petService');
const missionService = require('../services/missionService');

// 1. Bắt đầu phiên Pomodoro mới
const startPomodoroSession = async (req, res) => {
  try {
    const { userId, taskId, focusMinutes, breakMinutes, sessionsPlanned } = req.body;
    const resolvedUserId = (req.user && req.user.id) || userId;

    if (!resolvedUserId) {
      return res.status(400).json({ success: false, message: 'Thiếu thông tin userId!' });
    }

    const session = await prisma.pomodoroSession.create({
      data: {
        userId: resolvedUserId,
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

// 2. Kết thúc phiên Pomodoro, cộng Token vào ví & kiểm tra nhiệm vụ tự động trong ngày
const endPomodoroSession = async (req, res) => {
  try {
    const { sessionId, sessionsCompleted, xpEarned, tokenEarned } = req.body;

    if (!sessionId) {
      return res.status(400).json({ success: false, message: 'Thiếu sessionId!' });
    }

    const finalXp = xpEarned || 25;
    const finalToken = tokenEarned || 15;

    // Cập nhật phiên pomodoro thành đã hoàn thành
    const updatedSession = await prisma.pomodoroSession.update({
      where: { id: sessionId },
      data: {
        sessionsCompleted: sessionsCompleted || 1,
        isCompleted: true,
        xpEarned: finalXp,
        tokenEarned: finalToken,
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
      },
      create: {
        userId: updatedSession.userId,
        date: today,
        pomodoroSessions: 1,
        focusMinutes: updatedSession.focusMinutes,
        xpEarned: updatedSession.xpEarned,
      },
    });

    // Cộng Token trực tiếp vào ví và lưu lịch sử giao dịch rõ lý do (chống cộng lặp với referenceId)
    const pomoRefId = `pomodoro:${updatedSession.id}`;
    let alreadyAwarded = false;
    if (finalToken > 0) {
      const result = await walletService.adjustBalance(
        updatedSession.userId,
        finalToken,
        'REWARD',
        `Hoàn thành phiên tập trung Pomodoro (${updatedSession.focusMinutes} phút)`,
        pomoRefId
      );
      alreadyAwarded = Boolean(result && result.alreadyAwarded);
    }

    if (!alreadyAwarded && finalXp > 0) {
      try {
        await petService.gainXp(updatedSession.userId, finalXp);
      } catch (_) {}
    }

    // Tự động kiểm tra và trao thưởng các nhiệm vụ tự động hàng ngày (Pomodoro / Focus 60 phút)
    const missionEvaluation = await missionService.evaluateAndAutoRewardMissions(updatedSession.userId);

    return res.status(200).json({
      success: true,
      message: `Hoàn thành phiên Pomodoro (+${finalToken} Token)!`,
      data: updatedSession,
      missionEvaluation,
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
