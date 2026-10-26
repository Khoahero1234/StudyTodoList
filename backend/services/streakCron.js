// backend/services/streakCron.js

const cron = require('node-cron');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Checks login streak for all users daily at midnight.
 * If a user did not log in yesterday (or lastLoginDate < yesterday), reset currentStreak to 0.
 */
function initStreakCron() {
    // Runs every day at midnight: '0 0 * * *'
    cron.schedule('0 0 * * *', async () => {
        try {
            console.log('[streakCron] Running daily login streak check...');
            const streaks = await prisma.loginStreak.findMany();
            const now = new Date();
            const yesterday = new Date(now);
            yesterday.setDate(yesterday.getDate() - 1);
            yesterday.setHours(0, 0, 0, 0);

            for (const streak of streaks) {
                if (!streak.lastLoginDate) continue;
                const lastLogin = new Date(streak.lastLoginDate);
                lastLogin.setHours(0, 0, 0, 0);

                if (lastLogin < yesterday) {
                    await prisma.loginStreak.update({
                        where: { id: streak.id },
                        data: { currentStreak: 0 }
                    });
                    await prisma.user.update({
                        where: { id: streak.userId },
                        data: { currentStreak: 0 }
                    });
                }
            }
            console.log('[streakCron] Login streak check completed successfully.');
        } catch (error) {
            console.error('[streakCron] Error running daily streak check:', error);
        }
    });
}

module.exports = { initStreakCron };
