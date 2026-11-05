const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const VALID_TX_TYPES = new Set([
    'PURCHASE',
    'SPEND',
    'REWARD',
    'REFUND',
    'BONUS',
    'PREMIUM',
]);

function normalizeTransactionType(type, amount) {
    const upper = (type || '').toString().toUpperCase();
    if (VALID_TX_TYPES.has(upper)) return upper;
    if (upper === 'EARNED' || upper === 'MISSION' || upper === 'TASK') return 'REWARD';
    if (upper === 'SPENT' || upper === 'BUY' || upper === 'ORDER') return 'SPEND';
    return amount >= 0 ? 'REWARD' : 'SPEND';
}

async function _adjustBalanceInTx(tx, userId, amount, type, description = '', referenceId = null) {
    let wallet = await tx.wallet.findUnique({
        where: { userId }
    });

    if (!wallet) {
        wallet = await tx.wallet.create({
            data: {
                userId,
                balance: 0
            }
        });
    }

    const delta = Number(amount);
    if (Number.isNaN(delta)) {
        throw new Error('Số lượng Token không hợp lệ');
    }

    const normalizedType = normalizeTransactionType(type, delta);

    // Chống trùng lặp tuyệt đối (Idempotency check):
    // Nếu giao dịch có referenceId (như id task, id mission ngày, id session pomodoro) và cùng chiều cộng token,
    // kiểm tra xem đã từng được ghi nhận cho user chưa. Nếu đã có thì không cộng lặp!
    if (referenceId && delta > 0) {
        const existingTx = await tx.tokenTransaction.findFirst({
            where: {
                userId,
                referenceId: String(referenceId)
            }
        });
        if (existingTx) {
            console.log(`[IDEMPOTENCY] Bỏ qua cộng trùng Token cho referenceId: ${referenceId} (User: ${userId})`);
            return { wallet, transaction: existingTx, alreadyAwarded: true };
        }
    }

    const newBalance = wallet.balance + delta;
    if (newBalance < 0) {
        const err = new Error(`Số dư Token không đủ (hiện có ${wallet.balance} Token, cần ${Math.abs(delta)} Token)`);
        err.statusCode = 400;
        err.code = 'INSUFFICIENT_BALANCE';
        throw err;
    }

    const updatedWallet = await tx.wallet.update({
        where: { id: wallet.id },
        data: { balance: newBalance }
    });

    const transaction = await tx.tokenTransaction.create({
        data: {
            userId,
            walletId: wallet.id,
            amount: delta,
            balanceAfter: newBalance,
            type: normalizedType,
            description: description || (delta >= 0 ? 'Nhận Token' : 'Chi tiêu Token'),
            referenceId: referenceId ? String(referenceId) : null
        }
    });

    // Đồng bộ thống kê năng suất trong ngày (tokensEarned / tokensSpent)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    if (delta !== 0) {
        await tx.productivityStatistic.upsert({
            where: {
                userId_date: {
                    userId,
                    date: today
                }
            },
            update: delta > 0
                ? { tokensEarned: { increment: delta } }
                : { tokensSpent: { increment: Math.abs(delta) } },
            create: {
                userId,
                date: today,
                tokensEarned: delta > 0 ? delta : 0,
                tokensSpent: delta < 0 ? Math.abs(delta) : 0
            }
        });
    }

    return { wallet: updatedWallet, transaction };
}

/**
 * Adjusts user wallet balance and creates a transaction record atomically.
 * @param {string} userId
 * @param {number} amount (can be positive or negative)
 * @param {string} type e.g., 'PURCHASE', 'SPEND', 'REWARD', 'REFUND', 'BONUS', 'PREMIUM'
 * @param {string} description
 * @param {string} referenceId
 * @param {object} [externalTx] Optional Prisma transaction client
 */
async function adjustBalance(userId, amount, type, description = '', referenceId = null, externalTx = null) {
    if (externalTx) {
        return await _adjustBalanceInTx(externalTx, userId, amount, type, description, referenceId);
    }
    return await prisma.$transaction(async (tx) => {
        return await _adjustBalanceInTx(tx, userId, amount, type, description, referenceId);
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
        wallet = await prisma.wallet.create({
            data: {
                userId,
                balance: 0
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
        balance: wallet.balance,
        transactions,
        pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit) || 1
        }
    };
}

module.exports = {
    adjustBalance,
    getWallet,
    getTransactions,
    normalizeTransactionType
};
