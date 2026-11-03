const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

/**
 * Adjusts user wallet balance and creates a transaction record atomically.
 * @param {string} userId
 * @param {number} amount (can be positive or negative)
 * @param {string} type e.g., 'EARNED', 'SPENT', 'REWARD', 'BONUS'
 * @param {string} description
 * @param {string} referenceId
 */
async function adjustBalance(userId, amount, type, description = '', referenceId = null) {
    return await prisma.$transaction(async (tx) => {
        let wallet = await tx.wallet.findUnique({
            where: { userId }
        });

        if (!wallet) {
            const user = await tx.user.findUnique({ where: { id: userId } });
            const initialBalance = user ? user.tokenBalance : 0;
            wallet = await tx.wallet.create({
                data: {
                    userId,
                    balance: initialBalance
                }
            });
        }

        const newBalance = wallet.balance + amount;
        if (newBalance < 0) {
            throw new Error('Insufficient token balance');
        }

        const updatedWallet = await tx.wallet.update({
            where: { id: wallet.id },
            data: { balance: newBalance }
        });

        await tx.user.update({
            where: { id: userId },
            data: { tokenBalance: newBalance }
        });

        const transaction = await tx.tokenTransaction.create({
            data: {
                walletId: wallet.id,
                amount,
                type,
                description,
                referenceId
            }
        });

        return { wallet: updatedWallet, transaction };
    });
}

async function getWallet(userId) {
    let wallet = await prisma.wallet.findUnique({
        where: { userId },
        include: {
            transactions: {
                orderBy: { createdAt: 'desc' },
                take: 10
            }
        }
    });

    if (!wallet) {
        const user = await prisma.user.findUnique({ where: { id: userId } });
        const initialBalance = user ? user.tokenBalance : 0;
        wallet = await prisma.wallet.create({
            data: {
                userId,
                balance: initialBalance
            },
            include: {
                transactions: true
            }
        });
    }

    return wallet;
}

async function getTransactions(userId, page = 1, limit = 20) {
    let wallet = await prisma.wallet.findUnique({
        where: { userId }
    });

    if (!wallet) {
        wallet = await prisma.wallet.create({
            data: { userId, balance: 0 }
        });
    }

    const skip = (page - 1) * limit;
    const [transactions, total] = await Promise.all([
        prisma.tokenTransaction.findMany({
            where: { walletId: wallet.id },
            orderBy: { createdAt: 'desc' },
            skip,
            take: limit
        }),
        prisma.tokenTransaction.count({
            where: { walletId: wallet.id }
        })
    ]);

    return {
        transactions,
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit)
        }
    };
}

module.exports = {
    adjustBalance,
    getWallet,
    getTransactions
};
