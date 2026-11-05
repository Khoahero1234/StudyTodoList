const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// GET /admin/categories — Lấy tất cả ProductCategory
exports.getAllCategories = async (req, res) => {
    try {
        const categories = await prisma.productCategory.findMany({
            include: { _count: { select: { products: true } } },
            orderBy: { sortOrder: 'asc' }
        });
        res.json({ success: true, data: categories });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// POST /admin/categories — Tạo category mới
exports.createCategory = async (req, res) => {
    try {
        const { name, description, iconUrl, sortOrder } = req.body;

        if (!name) {
            return res.status(400).json({ success: false, message: 'name là bắt buộc' });
        }

        const category = await prisma.productCategory.create({
            data: {
                name,
                description,
                iconUrl,
                sortOrder: sortOrder !== undefined ? parseInt(sortOrder) : 0
            }
        });

        res.status(201).json({ success: true, data: category });
    } catch (error) {
        if (error.code === 'P2002') {
            return res.status(400).json({ success: false, message: 'Tên category đã tồn tại' });
        }
        res.status(500).json({ success: false, message: error.message });
    }
};

// PUT /admin/categories/:id — Cập nhật category
exports.updateCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, description, iconUrl, sortOrder } = req.body;

        const existing = await prisma.productCategory.findUnique({ where: { id } });
        if (!existing) {
            return res.status(404).json({ success: false, message: 'Category không tồn tại' });
        }

        const category = await prisma.productCategory.update({
            where: { id },
            data: {
                ...(name !== undefined && { name }),
                ...(description !== undefined && { description }),
                ...(iconUrl !== undefined && { iconUrl }),
                ...(sortOrder !== undefined && { sortOrder: parseInt(sortOrder) })
            }
        });

        res.json({ success: true, data: category });
    } catch (error) {
        if (error.code === 'P2002') {
            return res.status(400).json({ success: false, message: 'Tên category đã tồn tại' });
        }
        res.status(500).json({ success: false, message: error.message });
    }
};

// DELETE /admin/categories/:id — Xóa category (chỉ xóa nếu không có product)
exports.deleteCategory = async (req, res) => {
    try {
        const { id } = req.params;

        const existing = await prisma.productCategory.findUnique({
            where: { id },
            include: { _count: { select: { products: true } } }
        });
        if (!existing) {
            return res.status(404).json({ success: false, message: 'Category không tồn tại' });
        }
        if (existing._count.products > 0) {
            return res.status(400).json({
                success: false,
                message: `Không thể xóa: category đang chứa ${existing._count.products} sản phẩm`
            });
        }

        await prisma.productCategory.delete({ where: { id } });
        res.json({ success: true, message: 'Đã xóa category thành công' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
