const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// GET /admin/products — Lấy toàn bộ sản phẩm (kể cả đã ẩn/xóa mềm)
exports.getAllProducts = async (req, res) => {
    try {
        const { categoryId, isAvailable, page = 1, limit = 20 } = req.query;
        const skip = (parseInt(page) - 1) * parseInt(limit);

        const where = { deletedAt: null };
        if (categoryId) where.categoryId = categoryId;
        if (isAvailable !== undefined) where.isAvailable = isAvailable === 'true';

        const [products, total] = await Promise.all([
            prisma.product.findMany({
                where,
                include: { category: { select: { id: true, name: true } } },
                skip,
                take: parseInt(limit),
                orderBy: { createdAt: 'desc' }
            }),
            prisma.product.count({ where })
        ]);

        res.json({ success: true, data: products, total, page: parseInt(page), limit: parseInt(limit) });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// POST /admin/products — Tạo sản phẩm mới
exports.createProduct = async (req, res) => {
    try {
        const {
            name, description, imageUrl, price, categoryId,
            rarity, stock, discountPct, isAvailable, isPremiumOnly
        } = req.body;

        if (!name || !price || !categoryId) {
            return res.status(400).json({ success: false, message: 'name, price, categoryId là bắt buộc' });
        }

        const product = await prisma.product.create({
            data: {
                name,
                description,
                imageUrl,
                price: parseInt(price),
                categoryId,
                rarity: rarity || 'COMMON',
                stock: stock !== undefined ? parseInt(stock) : -1,
                discountPct: discountPct !== undefined ? parseInt(discountPct) : 0,
                isAvailable: isAvailable !== undefined ? Boolean(isAvailable) : true,
                isPremiumOnly: isPremiumOnly !== undefined ? Boolean(isPremiumOnly) : false
            },
            include: { category: { select: { id: true, name: true } } }
        });

        res.status(201).json({ success: true, data: product });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// PUT /admin/products/:id — Cập nhật sản phẩm
exports.updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const {
            name, description, imageUrl, price, categoryId,
            rarity, stock, discountPct, isAvailable, isPremiumOnly
        } = req.body;

        const existing = await prisma.product.findFirst({ where: { id, deletedAt: null } });
        if (!existing) {
            return res.status(404).json({ success: false, message: 'Sản phẩm không tồn tại' });
        }

        const product = await prisma.product.update({
            where: { id },
            data: {
                ...(name !== undefined && { name }),
                ...(description !== undefined && { description }),
                ...(imageUrl !== undefined && { imageUrl }),
                ...(price !== undefined && { price: parseInt(price) }),
                ...(categoryId !== undefined && { categoryId }),
                ...(rarity !== undefined && { rarity }),
                ...(stock !== undefined && { stock: parseInt(stock) }),
                ...(discountPct !== undefined && { discountPct: parseInt(discountPct) }),
                ...(isAvailable !== undefined && { isAvailable: Boolean(isAvailable) }),
                ...(isPremiumOnly !== undefined && { isPremiumOnly: Boolean(isPremiumOnly) })
            },
            include: { category: { select: { id: true, name: true } } }
        });

        res.json({ success: true, data: product });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// DELETE /admin/products/:id — Xóa mềm sản phẩm
exports.deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;

        const existing = await prisma.product.findFirst({ where: { id, deletedAt: null } });
        if (!existing) {
            return res.status(404).json({ success: false, message: 'Sản phẩm không tồn tại' });
        }

        await prisma.product.update({
            where: { id },
            data: { deletedAt: new Date(), isAvailable: false }
        });

        res.json({ success: true, message: 'Đã xóa sản phẩm thành công' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
