// backend/services/rewardService.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Retrieves or initializes the LoginStreak record for a given user,
 * updating the current/longest streak based on lastLoginDate.
 */
async function getOrCreateLoginStreak(userId) {
    let streak = await prisma.loginStreak.findUnique({
        where: { userId }
    });

    if (!streak) {
        streak = await prisma.loginStreak.create({
            data: {
                userId,
                currentStreak: 1,
                longestStreak: 1,
                lastLoginDate: new Date()
            }
        });

        await prisma.user.update({
            where: { id: userId },
            data: { currentStreak: 1 }
        });
    } else {
        const now = new Date();
        now.setHours(0, 0, 0, 0);

        const lastLogin = streak.lastLoginDate ? new Date(streak.lastLoginDate) : null;
        if (lastLogin) lastLogin.setHours(0, 0, 0, 0);

        if (!lastLogin || lastLogin.getTime() < now.getTime()) {
            const yesterday = new Date(now);
            yesterday.setDate(yesterday.getDate() - 1);

            let newStreak = streak.currentStreak;
            if (!lastLogin || lastLogin.getTime() === yesterday.getTime()) {
                newStreak += 1;
            } else if (lastLogin.getTime() < yesterday.getTime()) {
                newStreak = 1;
            }

            const newLongest = Math.max(newStreak, streak.longestStreak);

            streak = await prisma.loginStreak.update({
                where: { id: streak.id },
                data: {
                    currentStreak: newStreak,
                    longestStreak: newLongest,
                    lastLoginDate: new Date()
                }
            });

            await prisma.user.update({
                where: { id: userId },
                data: { currentStreak: newStreak }
            });
        }
    }

    return streak;
}

/**
 * Checks if a user is eligible to claim a given reward.
 * Throws an error if the reward is missing/inactive, already claimed, or streak condition is not met.
 */
async function checkRewardEligibility(userId, rewardId) {
    const reward = await prisma.reward.findUnique({
        where: { id: rewardId }
    });

    if (!reward || !reward.isActive) {
        throw new Error('Reward not found or is currently inactive');
    }

    const existingClaim = await prisma.userReward.findUnique({
        where: {
            userId_rewardId: { userId, rewardId }
        }
    });

    if (existingClaim) {
        throw new Error('You have already claimed this reward');
    }

    const streak = await getOrCreateLoginStreak(userId);

    if (streak.currentStreak < reward.requiredStreak) {
        throw new Error(`Required login streak of ${reward.requiredStreak} day(s) not met. Your current streak is ${streak.currentStreak} day(s).`);
    }

    return { reward, streak };
}

module.exports = {
    getOrCreateLoginStreak,
    checkRewardEligibility
};
