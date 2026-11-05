const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const walletService = require('./walletService');
const petService = require('./petService');

const DEFAULT_DAILY_MISSIONS = [
    {
        id: 'daily_checkin',
        title: 'Khởi động ngày mới',
        description: 'Mở ứng dụng và bắt đầu ngày học tập năng suất',
        category: 'DAILY',
        targetValue: 1,
        unit: 'lần',
        tokenReward: 15,
        xpReward: 20,
        icon: 'wb_sunny_rounded'
    },
    {
        id: 'complete_1_task',
        title: 'Chiến thần Deadline',
        description: 'Hoàn thành 1 công việc học tập bất kỳ trong ngày',
        category: 'TASK',
        targetValue: 1,
        unit: 'công việc',
        tokenReward: 25,
        xpReward: 30,
        icon: 'task_alt_rounded'
    },
    {
        id: 'complete_3_tasks',
        title: 'Chinh phục mục tiêu',
        description: 'Hoàn thành đủ 3 công việc học tập trong ngày',
        category: 'TASK',
        targetValue: 3,
        unit: 'công việc',
        tokenReward: 60,
        xpReward: 70,
        icon: 'emoji_events_rounded'
    },
    {
        id: 'pomodoro_1_session',
        title: 'Đồng hồ cà chua',
        description: 'Hoàn thành 1 phiên tập trung Pomodoro (25 phút)',
        category: 'POMODORO',
        targetValue: 1,
        unit: 'phiên',
        tokenReward: 30,
        xpReward: 35,
        icon: 'timer_rounded'
    },
    {
        id: 'focus_60_mins',
        title: 'Siêu tập trung 60 phút',
        description: 'Tích lũy đủ 60 phút học tập tập trung trong ngày',
        category: 'FOCUS',
        targetValue: 60,
        unit: 'phút',
        tokenReward: 50,
        xpReward: 60,
        icon: 'bolt_rounded'
    },
    {
        id: 'pomodoro_3_sessions',
        title: 'Bậc thầy bền bỉ',
        description: 'Hoàn thành 3 phiên tập trung Pomodoro trong ngày',
        category: 'POMODORO',
        targetValue: 3,
        unit: 'phiên',
        tokenReward: 80,
        xpReward: 100,
        icon: 'local_fire_department_rounded'
    }
];

function getTodayDateBounds() {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(startOfDay);
    endOfDay.setDate(endOfDay.getDate() + 1);

    const yyyy = startOfDay.getFullYear();
    const mm = String(startOfDay.getMonth() + 1).padStart(2, '0');
    const dd = String(startOfDay.getDate()).padStart(2, '0');
    const dateKey = `${yyyy}-${mm}-${dd}`;

    return { startOfDay, endOfDay, dateKey };
}

function getMissionRefId(missionId, dateKey) {
    return `mission:${missionId}:${dateKey}`;
}

/**
 * Tự động khởi tạo danh sách công việc học tập mẫu trong ngày cho user mới
 * để vừa sử dụng thực tế vừa dễ dàng bấm hoàn thành test nhận +Token.
 */
async function ensureDailyStudyTasks(userId, forceCreate = false) {
    const existingCount = await prisma.task.count({
        where: { userId }
    });

    if (existingCount > 0 && !forceCreate) {
        return [];
    }

    const now = new Date();
    const sampleTasks = [
        {
            userId,
            title: 'Ôn tập kiến thức Flutter & State Management (Riverpod)',
            description: 'Đọc lại tài liệu Provider/StateNotifier và kiểm tra luồng đồng bộ dữ liệu ví Token.',
            priority: 'HIGH',
            status: 'PENDING',
            dueDate: now,
            startTime: '09:00',
            tags: ['Flutter', 'PRM393'],
            estimatedMinutes: 30,
            tokenReward: 20,
            xpReward: 25
        },
        {
            userId,
            title: 'Hoàn thiện bài tập Backend RESTful API & Prisma ORM',
            description: 'Kiểm tra các API nhiệm vụ tự động, lịch sử cộng/trừ Token và giỏ hàng Shop.',
            priority: 'URGENT',
            status: 'PENDING',
            dueDate: now,
            startTime: '14:00',
            tags: ['Backend', 'NodeJS'],
            estimatedMinutes: 45,
            tokenReward: 30,
            xpReward: 40
        },
        {
            userId,
            title: 'Luyện tập 1 phiên tập trung Pomodoro 25 phút',
            description: 'Bật đồng hồ Pomodoro để tập trung giải quyết bài tập không bị xao nhãng.',
            priority: 'MEDIUM',
            status: 'PENDING',
            dueDate: now,
            startTime: '16:30',
            tags: ['Pomodoro', 'Focus'],
            estimatedMinutes: 25,
            tokenReward: 15,
            xpReward: 20
        },
        {
            userId,
            title: 'Tổng hợp ghi chú học tập & chuẩn bị bài ngày mai',
            description: 'Rà soát các công việc đã hoàn thành trong ngày và lên kế hoạch cho buổi học tiếp theo.',
            priority: 'LOW',
            status: 'PENDING',
            dueDate: now,
            startTime: '20:00',
            tags: ['Review', 'Daily'],
            estimatedMinutes: 15,
            tokenReward: 15,
            xpReward: 15
        }
    ];

    const created = [];
    for (const item of sampleTasks) {
        const t = await prisma.task.create({
            data: item,
            include: { subTasks: true, category: true }
        });
        created.push(t);
    }

    return created;
}

const activeEvaluations = new Map();

/**
 * Lấy thống kê hoạt động thực tế trong ngày của user và tự động kiểm tra,
 * đánh dấu hoàn thành + cộng thưởng Token cho các nhiệm vụ đạt chỉ tiêu.
 * Sử dụng hàng đợi Promise deduplication để tránh gọi song song cùng 1 user.
 */
async function evaluateAndAutoRewardMissions(userId) {
    if (activeEvaluations.has(userId)) {
        return activeEvaluations.get(userId);
    }
    const promise = _evaluateAndAutoRewardMissionsInternal(userId).finally(() => {
        activeEvaluations.delete(userId);
    });
    activeEvaluations.set(userId, promise);
    return promise;
}

async function _evaluateAndAutoRewardMissionsInternal(userId) {
    const { startOfDay, endOfDay, dateKey } = getTodayDateBounds();

    // Đảm bảo user luôn có ít nhất bộ task mẫu nếu tài khoản mới tạo
    await ensureDailyStudyTasks(userId, false);

    // Đếm số task đã hoàn thành thực tế trong ngày từ bảng Task
    const completedTasksTodayCount = await prisma.task.count({
        where: {
            userId,
            status: 'COMPLETED',
            completedAt: {
                gte: startOfDay,
                lt: endOfDay
            }
        }
    });

    // Đếm số phiên Pomodoro đã hoàn thành thực tế trong ngày
    const completedPomodorosToday = await prisma.pomodoroSession.findMany({
        where: {
            userId,
            isCompleted: true,
            endedAt: {
                gte: startOfDay,
                lt: endOfDay
            }
        }
    });

    const pomodoroCountFromSessions = completedPomodorosToday.length;
    const focusMinsFromSessions = completedPomodorosToday.reduce(
        (sum, s) => sum + (s.focusMinutes || 25),
        0
    );

    // Lấy hoặc tạo bản ghi thống kê năng suất hôm nay
    let todayStat = await prisma.productivityStatistic.findUnique({
        where: {
            userId_date: {
                userId,
                date: startOfDay
            }
        }
    });

    if (!todayStat) {
        todayStat = await prisma.productivityStatistic.create({
            data: {
                userId,
                date: startOfDay,
                tasksCompleted: completedTasksTodayCount,
                pomodoroSessions: pomodoroCountFromSessions,
                focusMinutes: focusMinsFromSessions
            }
        });
    } else {
        // Đồng bộ giá trị lớn nhất giữa bảng thống kê và dữ liệu thực tế
        const syncedTasks = Math.max(todayStat.tasksCompleted, completedTasksTodayCount);
        const syncedPomodoros = Math.max(todayStat.pomodoroSessions, pomodoroCountFromSessions);
        const syncedFocus = Math.max(todayStat.focusMinutes, focusMinsFromSessions);

        if (
            syncedTasks !== todayStat.tasksCompleted ||
            syncedPomodoros !== todayStat.pomodoroSessions ||
            syncedFocus !== todayStat.focusMinutes
        ) {
            todayStat = await prisma.productivityStatistic.update({
                where: { id: todayStat.id },
                data: {
                    tasksCompleted: syncedTasks,
                    pomodoroSessions: syncedPomodoros,
                    focusMinutes: syncedFocus
                }
            });
        }
    }

    // Kiểm tra các nhiệm vụ đã được cộng thưởng hôm nay thông qua TokenTransaction.referenceId
    const refIds = DEFAULT_DAILY_MISSIONS.map((m) => getMissionRefId(m.id, dateKey));
    const existingRewardTxs = await prisma.tokenTransaction.findMany({
        where: {
            userId,
            referenceId: { in: refIds }
        }
    });

    const rewardedMap = new Map();
    for (const tx of existingRewardTxs) {
        if (tx.referenceId) {
            rewardedMap.set(tx.referenceId, tx);
        }
    }

    const newlyCompleted = [];
    const missionsWithProgress = [];

    for (const mission of DEFAULT_DAILY_MISSIONS) {
        let rawProgress = 0;
        if (mission.category === 'DAILY') {
            rawProgress = 1; // Tự động hoàn thành khi mở app/kiểm tra nhiệm vụ trong ngày
        } else if (mission.category === 'TASK') {
            rawProgress = todayStat.tasksCompleted;
        } else if (mission.category === 'POMODORO') {
            rawProgress = todayStat.pomodoroSessions;
        } else if (mission.category === 'FOCUS') {
            rawProgress = todayStat.focusMinutes;
        }

        const currentProgress = Math.min(rawProgress, mission.targetValue);
        const isTargetReached = rawProgress >= mission.targetValue;
        const refId = getMissionRefId(mission.id, dateKey);
        let rewardTx = rewardedMap.get(refId);

        // Nếu vừa đạt chỉ tiêu và chưa nhận thưởng hôm nay -> Tự động hoàn thành & Cộng Token + Lưu lịch sử rõ lý do!
        if (isTargetReached && !rewardTx) {
            const reason = `Hoàn thành nhiệm vụ tự động: ${mission.title} (${mission.targetValue}/${mission.targetValue} ${mission.unit})`;
            const result = await walletService.adjustBalance(
                userId,
                mission.tokenReward,
                'REWARD',
                reason,
                refId
            );
            rewardTx = result.transaction;
            rewardedMap.set(refId, rewardTx);

            if (!result.alreadyAwarded) {
                if (mission.xpReward > 0) {
                    try {
                        await petService.gainXp(userId, mission.xpReward);
                    } catch (_) {}
                }

                newlyCompleted.push({
                    ...mission,
                    currentProgress,
                    isCompleted: true,
                    rewardedAt: rewardTx.createdAt,
                    rewardReason: reason
                });
            }
        }

        missionsWithProgress.push({
            ...mission,
            currentProgress,
            rawProgress,
            isCompleted: isTargetReached && Boolean(rewardTx),
            rewardedAt: rewardTx ? rewardTx.createdAt : null,
            progressPercentage: Math.min(100, Math.round((currentProgress / mission.targetValue) * 100))
        });
    }

    const walletInfo = await walletService.getWallet(userId);

    return {
        dateKey,
        stats: {
            tasksCompleted: todayStat.tasksCompleted,
            pomodoroSessions: todayStat.pomodoroSessions,
            focusMinutes: todayStat.focusMinutes,
            tokensEarnedToday: todayStat.tokensEarned
        },
        missions: missionsWithProgress,
        newlyCompleted,
        totalTokensAwardedNow: newlyCompleted.reduce((sum, m) => sum + m.tokenReward, 0),
        walletBalance: walletInfo.balance,
        recentTransactions: walletInfo.transactions || []
    };
}

/**
 * Mô phỏng / Kích hoạt hoạt động học tập để vừa sử dụng thực tế vừa dễ dàng test
 * tính năng tự động hoàn thành task, +token và lưu lịch sử +token vì lý do gì.
 */
async function trackActivity(userId, { type, value = 1 }) {
    const { startOfDay, dateKey } = getTodayDateBounds();
    const actionType = (type || '').toString().toUpperCase();

    let activityTokensAwarded = 0;
    let activityReason = '';
    let completedTaskData = null;

    // Đảm bảo bản ghi thống kê hôm nay tồn tại
    await prisma.productivityStatistic.upsert({
        where: {
            userId_date: {
                userId,
                date: startOfDay
            }
        },
        update: {},
        create: {
            userId,
            date: startOfDay
        }
    });

    if (actionType === 'TASK_COMPLETED') {
        // Tìm 1 task đang PENDING của user để tự động chuyển sang COMPLETED thật sự
        let pendingTask = await prisma.task.findFirst({
            where: {
                userId,
                status: { not: 'COMPLETED' }
            },
            orderBy: { createdAt: 'asc' }
        });

        if (!pendingTask) {
            // Nếu user đã làm hết task, tự động tạo 1 task học tập mới và hoàn thành luôn
            pendingTask = await prisma.task.create({
                data: {
                    userId,
                    title: `Bài tập thực hành tự động #${Math.floor(100 + Math.random() * 900)}`,
                    description: 'Công việc học tập được tạo và hoàn thành từ bảng kiểm thử tự động.',
                    priority: 'HIGH',
                    status: 'PENDING',
                    dueDate: new Date(),
                    estimatedMinutes: 20,
                    tokenReward: 15,
                    xpReward: 20
                }
            });
        }

        completedTaskData = await prisma.task.update({
            where: { id: pendingTask.id },
            data: {
                status: 'COMPLETED',
                completedAt: new Date(),
                actualMinutes: pendingTask.estimatedMinutes || 20
            },
            include: { subTasks: true, category: true }
        });

        const taskToken = completedTaskData.tokenReward || 15;
        const taskXp = completedTaskData.xpReward || 20;
        activityReason = `Hoàn thành công việc: ${completedTaskData.title}`;

        await walletService.adjustBalance(
            userId,
            taskToken,
            'REWARD',
            activityReason,
            completedTaskData.id
        );
        activityTokensAwarded += taskToken;

        try {
            await petService.gainXp(userId, taskXp);
        } catch (_) {}

        await prisma.productivityStatistic.update({
            where: {
                userId_date: {
                    userId,
                    date: startOfDay
                }
            },
            data: {
                tasksCompleted: { increment: 1 },
                focusMinutes: { increment: completedTaskData.estimatedMinutes || 15 }
            }
        });
    } else if (actionType === 'POMODORO_COMPLETED') {
        const focusMins = Number(value) > 1 ? Number(value) : 25;
        const pomoToken = 15;
        const pomoXp = 25;

        const session = await prisma.pomodoroSession.create({
            data: {
                userId,
                focusMinutes: focusMins,
                breakMinutes: 5,
                sessionsPlanned: 1,
                sessionsCompleted: 1,
                isCompleted: true,
                xpEarned: pomoXp,
                tokenEarned: pomoToken,
                endedAt: new Date()
            }
        });

        activityReason = `Hoàn thành phiên tập trung Pomodoro (${focusMins} phút)`;
        await walletService.adjustBalance(
            userId,
            pomoToken,
            'REWARD',
            activityReason,
            session.id
        );
        activityTokensAwarded += pomoToken;

        try {
            await petService.gainXp(userId, pomoXp);
        } catch (_) {}

        await prisma.productivityStatistic.update({
            where: {
                userId_date: {
                    userId,
                    date: startOfDay
                }
            },
            data: {
                pomodoroSessions: { increment: 1 },
                focusMinutes: { increment: focusMins }
            }
        });
    } else if (actionType === 'FOCUS_MINUTES') {
        const mins = Number(value) > 0 ? Number(value) : 30;
        const focusToken = 10;
        activityReason = `Tích lũy ${mins} phút học tập tập trung`;

        await walletService.adjustBalance(
            userId,
            focusToken,
            'REWARD',
            activityReason,
            `focus:${Date.now()}`
        );
        activityTokensAwarded += focusToken;

        await prisma.productivityStatistic.update({
            where: {
                userId_date: {
                    userId,
                    date: startOfDay
                }
            },
            data: {
                focusMinutes: { increment: mins }
            }
        });
    } else if (actionType === 'RESET_TODAY_MISSIONS') {
        // Cho phép đặt lại tiến độ nhiệm vụ trong ngày để user có thể test lại nhiều lần
        const refIds = DEFAULT_DAILY_MISSIONS.map((m) => getMissionRefId(m.id, dateKey));
        await prisma.tokenTransaction.deleteMany({
            where: {
                userId,
                referenceId: { in: refIds }
            }
        });

        await prisma.productivityStatistic.update({
            where: {
                userId_date: {
                    userId,
                    date: startOfDay
                }
            },
            data: {
                tasksCompleted: 0,
                pomodoroSessions: 0,
                focusMinutes: 0
            }
        });

        // Đặt lại các task đã hoàn thành hôm nay về PENDING để dễ test lại
        await prisma.task.updateMany({
            where: {
                userId,
                status: 'COMPLETED'
            },
            data: {
                status: 'PENDING',
                completedAt: null
            }
        });

        await prisma.pomodoroSession.deleteMany({
            where: {
                userId,
                endedAt: { gte: startOfDay }
            }
        });

        activityReason = 'Đã đặt lại tiến độ nhiệm vụ hôm nay để kiểm thử lại';
    }

    // Đánh giá lại toàn bộ nhiệm vụ tự động trong ngày và cộng thưởng nếu có nhiệm vụ đạt mốc
    const evaluation = await evaluateAndAutoRewardMissions(userId);
    const missionBonusTokens = evaluation.totalTokensAwardedNow;
    const totalAdded = activityTokensAwarded + missionBonusTokens;

    return {
        ...evaluation,
        activityTokensAwarded,
        missionBonusTokens,
        totalTokensAwarded: totalAdded,
        activityReason,
        completedTask: completedTaskData
    };
}

module.exports = {
    DEFAULT_DAILY_MISSIONS,
    ensureDailyStudyTasks,
    evaluateAndAutoRewardMissions,
    trackActivity
};
