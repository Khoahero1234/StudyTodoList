const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getCategories = async (req, res) => {
    try {
        const categories = await prisma.category.findMany({
            where: { userId: req.user.id },
            orderBy: { createdAt: 'asc' },
            include: {
                _count: {
                    select: { tasks: true }
                }
            }
        });

        res.json({ success: true, data: categories });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getCategoryById = async (req, res) => {
    try {
        const category = await prisma.category.findFirst({
            where: { id: req.params.id, userId: req.user.id },
            include: { tasks: true }
        });

        if (!category) return res.status(404).json({ success: false, message: 'Category not found' });

        res.json({ success: true, data: category });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.createCategory = async (req, res) => {
    try {
        const { name, color, icon } = req.body;

        if (!name) return res.status(400).json({ success: false, message: 'Category name is required' });

        const category = await prisma.category.create({
            data: {
                userId: req.user.id,
                name,
                color: color || '#6C63FF',
                icon
            }
        });

        res.status(201).json({ success: true, data: category });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateCategory = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, color, icon } = req.body;

        const existing = await prisma.category.findFirst({
            where: { id, userId: req.user.id }
        });

        if (!existing) return res.status(404).json({ success: false, message: 'Category not found' });

        const dataToUpdate = {};
        if (name !== undefined) dataToUpdate.name = name;
        if (color !== undefined) dataToUpdate.color = color;
        if (icon !== undefined) dataToUpdate.icon = icon;

        const category = await prisma.category.update({
            where: { id },
            data: dataToUpdate
        });

        res.json({ success: true, data: category });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteCategory = async (req, res) => {
    try {
        const { id } = req.params;

        const existing = await prisma.category.findFirst({
            where: { id, userId: req.user.id }
        });

        if (!existing) return res.status(404).json({ success: false, message: 'Category not found' });

        // Unlink tasks before deleting
        await prisma.task.updateMany({
            where: { categoryId: id },
            data: { categoryId: null }
        });

        await prisma.category.delete({ where: { id } });

        res.json({ success: true, message: 'Category deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
