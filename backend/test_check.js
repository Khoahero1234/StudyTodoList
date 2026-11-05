const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({ select: { id: true, username: true } });
  console.log('USERS:', users);
  const inv = await prisma.inventoryItem.findMany({ include: { product: { include: { category: true } } } });
  console.log('INV count:', inv.length);
  console.log('INV in DB:', JSON.stringify(inv, null, 2));
  const orders = await prisma.order.findMany({ include: { items: { include: { product: true } } } });
  console.log('ORDERS count:', orders.length);
}

main().finally(() => prisma.$disconnect());
