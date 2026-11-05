const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getGoals = async (req, res) => {
    try {
        const goals = await prisma.goal.findMany({
            where: { userId: req.user.id, deletedAt: null },
            orderBy: { createdAt: 'desc' }
        });

        res.json({ success: true, data: goals });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getGoalById = async (req, res) => {
    try {
        const goal = await prisma.goal.findFirst({
            where: { id: req.params.id, userId: req.user.id, deletedAt: null }
        });

        if (!goal) return res.status(404).json({ success: false, message: 'Goal not found' });

        res.json({ success: true, data: goal });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.createGoal = async (req, res) => {
    try {
        const { title, description, targetDate } = req.body;

        if (!title) return res.status(400).json({ success: false, message: 'Goal title is required' });

        const goal = await prisma.goal.create({
            data: {
                userId: req.user.id,
                title,
                description,
                targetDate: targetDate ? new Date(targetDate) : null
            }
        });

        res.status(201).json({ success: true, data: goal });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateGoal = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, targetDate, isCompleted } = req.body;

        const existing = await prisma.goal.findFirst({
            where: { id, userId: req.user.id, deletedAt: null }
        });

        if (!existing) return res.status(404).json({ success: false, message: 'Goal not found' });

        const dataToUpdate = {};
        if (title !== undefined) dataToUpdate.title = title;
        if (description !== undefined) dataToUpdate.description = description;
        if (targetDate !== undefined) dataToUpdate.targetDate = targetDate ? new Date(targetDate) : null;
        if (isCompleted !== undefined) dataToUpdate.isCompleted = Boolean(isCompleted);

        const goal = await prisma.goal.update({
            where: { id },
            data: dataToUpdate
        });

        res.json({ success: true, data: goal });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteGoal = async (req, res) => {
    try {
        const { id } = req.params;

        const existing = await prisma.goal.findFirst({
            where: { id, userId: req.user.id, deletedAt: null }
        });

        if (!existing) return res.status(404).json({ success: false, message: 'Goal not found' });

        await prisma.goal.update({
            where: { id },
            data: { deletedAt: new Date() }
        });

        res.json({ success: true, message: 'Goal deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
