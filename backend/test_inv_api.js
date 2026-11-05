require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const productDto = require('./dtos/productDto');

async function testInventory() {
    const user = await prisma.user.findFirst({ where: { username: 'lmtruong' } });
    console.log('Testing for user:', user.id, user.username);

    const inventoryItems = await prisma.inventoryItem.findMany({
        where: { userId: user.id },
        orderBy: { updatedAt: 'desc' },
        include: {
            product: {
                include: { category: true }
            }
        }
    });
    console.log('Raw inventoryItems:', JSON.stringify(inventoryItems, null, 2));

    const formatted = inventoryItems.map((item) => ({
        id: item.id,
        userId: item.userId,
        productId: item.productId,
        quantity: item.quantity,
        isEquipped: item.isEquipped,
        acquiredAt: item.acquiredAt,
        updatedAt: item.updatedAt,
        product: item.product ? productDto.formatProduct(item.product) : null
    }));

    console.log('Formatted response data:', JSON.stringify({ items: formatted, total: formatted.length }, null, 2));
}

testInventory().finally(() => prisma.$disconnect());
