// backend/controllers/rewardController.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const rewardService = require('../services/rewardService');
const walletService = require('../services/walletService');
const petService = require('../services/petService');

/**
 * GET /api/rewards
 * Returns current login streak and active rewards with claim/eligibility status.
 */
exports.getRewards = async (req, res) => {
    try {
        const userId = req.user.id;
        const streak = await rewardService.getOrCreateLoginStreak(userId);

        const rewards = await prisma.reward.findMany({
            where: { isActive: true },
            orderBy: { requiredStreak: 'asc' }
        });

        const claimedRewards = await prisma.userReward.findMany({
            where: { userId }
        });

        const claimedIds = new Set(claimedRewards.map(cr => cr.rewardId));

        const formattedRewards = rewards.map(r => ({
            id: r.id,
            title: r.title,
            description: r.description,
            type: r.type,
            amount: r.amount,
            requiredStreak: r.requiredStreak,
            isClaimed: claimedIds.has(r.id),
            isEligible: streak.currentStreak >= r.requiredStreak
        }));

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

/**
 * POST /api/rewards/claim/:rewardId
 * Claims a daily streak reward if eligible. Calls walletService.adjustBalance for tokens.
 */
exports.claimReward = async (req, res) => {
    try {
        const userId = req.user.id;
        const { rewardId } = req.params;

        // Check eligibility via rewardService
        const { reward, streak } = await rewardService.checkRewardEligibility(userId, rewardId);

        // Perform reward claiming and distribution
        const userReward = await prisma.$transaction(async (tx) => {
            const claim = await tx.userReward.create({
                data: {
                    userId,
                    rewardId
                }
            });

            const rewardType = reward.type.toLowerCase();

            // Distribute reward according to type
            if (rewardType === 'token' || rewardType === 'reward') {
                // Mandatory reuse of Module 1 walletService.adjustBalance
                await walletService.adjustBalance(
                    userId,
                    reward.amount,
                    'REWARD',
                    `Claimed streak reward: ${reward.title}`,
                    reward.id
                );
            } else if (rewardType === 'xp') {
                await petService.gainXp(userId, reward.amount);
            } else if (rewardType === 'item') {
                // If reward specifies an item, find/upsert an item in InventoryItem
                const sampleProduct = await tx.product.findFirst({ where: { isAvailable: true } });
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
                message: `Successfully claimed ${reward.amount} ${reward.type}!`
            },
            error: null
        });
    } catch (error) {
        console.error('[rewardController] Error in claimReward:', error);
        res.status(400).json({ success: false, data: null, error: error.message });
    }
};
