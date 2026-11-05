// backend/controllers/rewardController.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const rewardService = require('../services/rewardService');
const walletService = require('../services/walletService');
const petService = require('../services/petService');

exports.getRewards = async (req, res) => {
    try {
        const userId = req.user.id;
        const streak = await rewardService.getOrCreateLoginStreak(userId);

        const rewards = await prisma.reward.findMany({
            where: { isActive: true },
            orderBy: { streakDay: 'asc' }
        });

        const claimedRewards = await prisma.userReward.findMany({
            where: { userId }
        });

        const claimedIds = new Set(claimedRewards.map(cr => cr.rewardId));

        const formattedRewards = rewards.map(r => {
            const reqStreak = r.streakDay ?? 1;
            return {
                id: r.id,
                title: r.name,
                name: r.name,
                description: r.description,
                type: r.type,
                amount: r.value,
                value: r.value,
                requiredStreak: reqStreak,
                streakDay: reqStreak,
                isClaimed: claimedIds.has(r.id),
                isEligible: streak.currentStreak >= reqStreak
            };
        });

        res.json({
            success: true,
            data: {
                streak: {
                    currentStreak: streak.currentStreak,
                    longestStreak: streak.longestStreak,
                    lastLoginDate: streak.lastLoginDate
                },
                rewards: formattedRewards
            },
            error: null
        });
    } catch (error) {
        console.error('[rewardController] Error in getRewards:', error);
        res.status(500).json({ success: false, data: null, error: error.message });
    }
};

exports.claimReward = async (req, res) => {
    try {
        const userId = req.user.id;
        const { rewardId } = req.params;

        const { reward } = await rewardService.checkRewardEligibility(userId, rewardId);
        const rewardAmount = reward.value ?? reward.amount ?? 0;
        const rewardTitle = reward.name ?? reward.title ?? 'Streak Reward';

        const userReward = await prisma.$transaction(async (tx) => {
            const claim = await tx.userReward.create({
                data: {
                    userId,
                    rewardId
                }
            });

            const rewardType = (reward.type || 'TOKEN').toLowerCase();

            if (rewardType === 'token' || rewardType === 'reward') {
                await walletService.adjustBalance(
                    userId,
                    rewardAmount,
                    'REWARD',
                    `Nhận thưởng chuỗi đăng nhập: ${rewardTitle}`,
                    reward.id,
                    tx
                );
            } else if (rewardType === 'xp') {
                await petService.gainXp(userId, rewardAmount);
            } else if (rewardType === 'item') {
                const sampleProduct = await tx.product.findFirst({ where: { isAvailable: true, deletedAt: null } });
                if (sampleProduct) {
                    await tx.inventoryItem.upsert({
                        where: {
                            userId_productId: { userId, productId: sampleProduct.id }
                        },
                        update: { quantity: { increment: 1 } },
                        create: {
                            userId,
                            productId: sampleProduct.id,
                            quantity: 1
                        }
                    });
                }
            }

            return claim;
        });

        res.json({
            success: true,
            data: {
                userReward,
                message: `Đã nhận thành công ${rewardAmount} ${reward.type}!`
            },
            error: null
        });
    } catch (error) {
        console.error('[rewardController] Error in claimReward:', error);
        res.status(400).json({ success: false, data: null, error: error.message });
    }
};
