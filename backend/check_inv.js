require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const p = new PrismaClient();

async function main() {
    const orders = await p.order.findMany({
        include: { items: { include: { product: true } } }
    });
    console.log('Orders in DB:', JSON.stringify(orders, null, 2));

    const inv = await p.inventoryItem.findMany({
        include: { product: true }
    });
    console.log('Inventory in DB:', JSON.stringify(inv, null, 2));
}

main().finally(() => p.$disconnect());
