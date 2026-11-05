require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function cleanDuplicates() {
    console.log('--- Cleaning Duplicate Token Transactions ---');
    const allTxs = await prisma.tokenTransaction.findMany({
        orderBy: { createdAt: 'asc' }
    });

    const seenRefs = new Set();
    const toDeleteIds = [];

    for (const tx of allTxs) {
        if (!tx.referenceId) continue;
        const key = `${tx.userId}_${tx.referenceId}`;
        if (seenRefs.has(key)) {
            toDeleteIds.push(tx.id);
            console.log(`Duplicate found: ID=${tx.id}, ref=${tx.referenceId}, amount=${tx.amount}, desc="${tx.description}"`);
        } else {
            seenRefs.add(key);
        }
    }

    if (toDeleteIds.length > 0) {
        console.log(`Deleting ${toDeleteIds.length} duplicate transactions...`);
        await prisma.tokenTransaction.deleteMany({
            where: { id: { in: toDeleteIds } }
        });
        console.log('Duplicates deleted.');
    } else {
        console.log('No duplicate transactions with referenceId found.');
    }

    // Recalculate true wallet balances for all users
    const users = await prisma.user.findMany({
        include: { wallet: true }
    });

    for (const user of users) {
        const remainingTxs = await prisma.tokenTransaction.findMany({
            where: { userId: user.id },
            orderBy: { createdAt: 'asc' }
        });

        let runningBalance = 0;
        for (const tx of remainingTxs) {
            runningBalance += tx.amount;
            if (tx.balanceAfter !== runningBalance) {
                await prisma.tokenTransaction.update({
                    where: { id: tx.id },
                    data: { balanceAfter: runningBalance }
                });
            }
        }

        if (user.wallet) {
            await prisma.wallet.update({
                where: { id: user.wallet.id },
                data: { balance: runningBalance }
            });
            console.log(`User ${user.username} wallet balance recalculated: ${runningBalance} Tokens`);
        }
    }
}

cleanDuplicates()
    .catch(console.error)
    .finally(() => prisma.$disconnect());
