// backend/controllers/orderController.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const walletService = require('../services/walletService');

exports.createOrder = async (req, res) => {
    try {
        const userId = req.user.id;
        const { items } = req.body; // [{ productId, quantity }]

        if (!items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json({ success: false, error: 'Order items are required' });
        }

        // 1. Fetch products and calculate total amount
        let totalAmount = 0;
        const orderItemsData = [];

        for (const item of items) {
            const { productId, quantity = 1 } = item;
            if (!productId || quantity <= 0) {
                return res.status(400).json({ success: false, error: 'Invalid product ID or quantity' });
            }

            const product = await prisma.product.findUnique({ where: { id: productId } });
            if (!product || !product.isAvailable) {
                return res.status(404).json({ success: false, error: `Product not found or unavailable: ${productId}` });
            }

            if (product.stock < quantity) {
                return res.status(400).json({ success: false, error: `Insufficient stock for product: ${product.name}` });
            }

            const itemPrice = Math.round(product.price * (1 - (product.discountPct || 0) / 100));
            totalAmount += itemPrice * quantity;

            orderItemsData.push({
                productId: product.id,
                quantity,
                price: itemPrice
            });
        }

        // 2. Adjust balance via walletService (deduct tokens), create order, update stock, and upsert inventory
        // First deduct balance using walletService.adjustBalance (it will throw if insufficient balance)
        await walletService.adjustBalance(
            userId,
            -totalAmount,
            'PURCHASE',
            `Purchase order items`
        );

        // 3. Create Order and update inventory within transaction
        const result = await prisma.$transaction(async (tx) => {
            const order = await tx.order.create({
                data: {
                    userId,
                    totalAmount,
                    status: 'completed',
                    items: {
                        create: orderItemsData
                    }
                },
                include: { items: { include: { product: true } } }
            });

            for (const orderItem of orderItemsData) {
                await tx.product.update({
                    where: { id: orderItem.productId },
                    data: { stock: { decrement: orderItem.quantity } }
                });

                await tx.inventoryItem.upsert({
                    where: {
                        userId_productId: {
                            userId,
                            productId: orderItem.productId
                        }
                    },
                    update: {
                        quantity: { increment: orderItem.quantity }
                    },
                    create: {
                        userId,
                        productId: orderItem.productId,
                        quantity: orderItem.quantity
                    }
                });
            }

            return order;
        });

        res.status(201).json({
            success: true,
            data: result
        });
    } catch (error) {
        console.error('Error in createOrder:', error);
        // If balance was deducted but order failed (though separated), handle appropriately.
        // Here adjustBalance is called first; if it throws 'Insufficient token balance', order creation is prevented.
        res.status(500).json({ success: false, error: error.message });
    }
};

exports.getOrders = async (req, res) => {
    try {
        const userId = req.user.id;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const [orders, total] = await Promise.all([
            prisma.order.findMany({
                where: { userId },
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: { items: { include: { product: true } } }
            }),
            prisma.order.count({ where: { userId } })
        ]);

        res.json({
            success: true,
            data: {
                orders,
                pagination: {
                    page,
                    limit,
                    total,
                    totalPages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Error in getOrders:', error);
        res.status(500).json({ success: false, error: error.message });
    }
};
