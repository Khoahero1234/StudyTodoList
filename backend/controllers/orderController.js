// backend/controllers/orderController.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const walletService = require('../services/walletService');
const productDto = require('../dtos/productDto');

exports.createOrder = async (req, res) => {
    try {
        const userId = req.user.id;
        let { items, productId, quantity } = req.body;

        // Hỗ trợ cả payload { items: [{ productId, quantity }] } và { productId, quantity }
        if ((!items || !Array.isArray(items) || items.length === 0) && productId) {
            items = [{ productId, quantity: quantity || 1 }];
        }

        if (!items || !Array.isArray(items) || items.length === 0) {
            return res.status(400).json({
                success: false,
                message: 'Danh sách sản phẩm mua không hợp lệ',
                error: 'Order items are required'
            });
        }

        // Gộp các item trùng productId nếu có
        const mergedItemsMap = new Map();
        for (const item of items) {
            const pId = item.productId;
            const qty = parseInt(item.quantity ?? 1, 10);
            if (!pId || Number.isNaN(qty) || qty <= 0) {
                return res.status(400).json({
                    success: false,
                    message: 'ID sản phẩm hoặc số lượng không hợp lệ (số lượng phải > 0)',
                    error: 'Invalid product ID or quantity'
                });
            }
            mergedItemsMap.set(pId, (mergedItemsMap.get(pId) || 0) + qty);
        }

        // Thực hiện kiểm tra tồn kho, trừ Token, tạo đơn hàng, trừ kho và thêm vào Kho đồ (Inventory) trong 1 Transaction nguyên tử
        const result = await prisma.$transaction(async (tx) => {
            let totalTokens = 0;
            const orderItemsData = [];

            for (const [pId, qty] of mergedItemsMap.entries()) {
                const product = await tx.product.findFirst({
                    where: { id: pId, deletedAt: null }
                });

                if (!product || !product.isAvailable) {
                    const err = new Error(`Sản phẩm không tồn tại hoặc đã ngừng bán`);
                    err.statusCode = 404;
                    throw err;
                }

                // Kiểm tra tồn kho (-1 là không giới hạn)
                if (product.stock !== -1 && product.stock < qty) {
                    const err = new Error(
                        product.stock <= 0
                            ? `Sản phẩm "${product.name}" đã hết hàng`
                            : `Sản phẩm "${product.name}" chỉ còn ${product.stock} sản phẩm trong kho`
                    );
                    err.statusCode = 400;
                    throw err;
                }

                const discountPct = product.discountPct || 0;
                const priceAtSale = discountPct > 0
                    ? Math.floor((product.price * (100 - discountPct)) / 100)
                    : product.price;

                totalTokens += priceAtSale * qty;

                orderItemsData.push({
                    productId: product.id,
                    productName: product.name,
                    currentStock: product.stock,
                    quantity: qty,
                    priceAtSale
                });
            }

            // 1. Tạo Order trước để lấy order.id làm referenceId cho giao dịch trừ Token
            const order = await tx.order.create({
                data: {
                    userId,
                    totalTokens,
                    status: 'COMPLETED',
                    items: {
                        create: orderItemsData.map((i) => ({
                            productId: i.productId,
                            quantity: i.quantity,
                            priceAtSale: i.priceAtSale
                        }))
                    }
                },
                include: {
                    items: {
                        include: {
                            product: {
                                include: { category: true }
                            }
                        }
                    }
                }
            });

            // 2. Trừ Token trong ví của người dùng (nếu không đủ Token sẽ throw lỗi và rollback toàn bộ transaction)
            const itemSummary = orderItemsData
                .map((i) => `${i.productName} (x${i.quantity})`)
                .join(', ');

            const { wallet: updatedWallet, transaction: tokenTx } = await walletService.adjustBalance(
                userId,
                -totalTokens,
                'SPEND',
                `Mua vật phẩm Shop: ${itemSummary}`,
                order.id,
                tx
            );

            // 3. Cập nhật tồn kho sản phẩm (nếu stock !== -1) và thêm vào Kho đồ (InventoryItem)
            const updatedInventory = [];
            for (const orderItem of orderItemsData) {
                if (orderItem.currentStock !== -1) {
                    await tx.product.update({
                        where: { id: orderItem.productId },
                        data: { stock: { decrement: orderItem.quantity } }
                    });
                }

                const invItem = await tx.inventoryItem.upsert({
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
                    },
                    include: {
                        product: {
                            include: { category: true }
                        }
                    }
                });
                updatedInventory.push(invItem);
            }

            return {
                order,
                walletBalance: updatedWallet.balance,
                deductedTokens: totalTokens,
                transaction: tokenTx,
                inventoryItems: updatedInventory
            };
        });

        res.status(201).json({
            success: true,
            message: `Mua hàng thành công! Đã trừ ${result.deductedTokens} Token.`,
            data: result
        });
    } catch (error) {
        console.error('Error in createOrder:', error);
        const statusCode = error.statusCode || (error.message && error.message.includes('Số dư Token không đủ') ? 400 : 500);
        res.status(statusCode).json({
            success: false,
            message: error.message || 'Mua hàng thất bại',
            error: error.message || 'Mua hàng thất bại'
        });
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
                include: {
                    items: {
                        include: {
                            product: {
                                include: { category: true }
                            }
                        }
                    }
                }
            }),
            prisma.order.count({ where: { userId } })
        ]);

        const formattedOrders = orders.map((order) => ({
            id: order.id,
            userId: order.userId,
            totalTokens: order.totalTokens,
            totalAmount: order.totalTokens,
            status: order.status,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
            items: order.items.map((item) => ({
                id: item.id,
                orderId: item.orderId,
                productId: item.productId,
                quantity: item.quantity,
                priceAtSale: item.priceAtSale,
                price: item.priceAtSale,
                product: item.product ? productDto.formatProduct(item.product) : null
            }))
        }));

        res.json({
            success: true,
            data: {
                orders: formattedOrders,
                pagination: {
                    page,
                    limit,
                    total,
                    totalPages: Math.ceil(total / limit) || 1
                }
            }
        });
    } catch (error) {
        console.error('Error in getOrders:', error);
        res.status(500).json({ success: false, message: error.message, error: error.message });
    }
};

exports.getInventory = async (req, res) => {
    try {
        const userId = req.user.id;
        const inventoryItems = await prisma.inventoryItem.findMany({
            where: { userId },
            orderBy: { updatedAt: 'desc' },
            include: {
                product: {
                    include: { category: true }
                }
            }
        });

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

        res.json({
            success: true,
            data: {
                items: formatted,
                total: formatted.length
            }
        });
    } catch (error) {
        console.error('Error in getInventory:', error);
        res.status(500).json({ success: false, message: error.message, error: error.message });
    }
};

exports.toggleEquipInventoryItem = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id } = req.params;

        const existing = await prisma.inventoryItem.findFirst({
            where: { id, userId },
            include: { product: { include: { category: true } } }
        });

        if (!existing) {
            return res.status(404).json({
                success: false,
                message: 'Không tìm thấy vật phẩm trong kho đồ',
                error: 'Inventory item not found'
            });
        }

        const updated = await prisma.inventoryItem.update({
            where: { id },
            data: { isEquipped: !existing.isEquipped },
            include: { product: { include: { category: true } } }
        });

        res.json({
            success: true,
            message: updated.isEquipped
                ? `Đã trang bị "${updated.product?.name || 'vật phẩm'}"`
                : `Đã gỡ trang bị "${updated.product?.name || 'vật phẩm'}"`,
            data: {
                ...updated,
                product: updated.product ? productDto.formatProduct(updated.product) : null
            }
        });
    } catch (error) {
        console.error('Error in toggleEquipInventoryItem:', error);
        res.status(500).json({ success: false, message: error.message, error: error.message });
    }
};
