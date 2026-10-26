const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const walletService = require('../services/walletService');
const petService = require('../services/petService');

exports.getTasks = async (req, res) => {
    try {
        const { status, priority, search, categoryId, page = 1, pageSize = 20 } = req.query;

        const where = { userId: req.user.id };
        if (status) where.status = status;
        if (priority) where.priority = priority;
        if (categoryId) where.categoryId = categoryId;
        if (search) {
            where.title = { contains: search, mode: 'insensitive' };
        }

        const skip = (parseInt(page) - 1) * parseInt(pageSize);
        
        const [tasks, total] = await Promise.all([
            prisma.task.findMany({
                where,
                skip,
                take: parseInt(pageSize),
                orderBy: { createdAt: 'desc' },
                include: { subTasks: true, category: true }
            }),
            prisma.task.count({ where })
        ]);

        res.json({
            success: true,
            data: tasks,
            meta: {
                total,
                page: parseInt(page),
                pageSize: parseInt(pageSize)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getTaskById = async (req, res) => {
    try {
        const task = await prisma.task.findFirst({
            where: { id: req.params.id, userId: req.user.id },
            include: { subTasks: true, category: true }
        });
        
        if (!task) return res.status(404).json({ success: false, message: 'Task not found' });
        
        res.json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.createTask = async (req, res) => {
    try {
        const { title, description, priority, dueDate, dueTime, categoryId, tags, estimatedMinutes, isRecurring, recurringPattern, tokenReward, xpReward } = req.body;
        
        const task = await prisma.task.create({
            data: {
                userId: req.user.id,
                title,
                description,
                priority: priority || 'medium',
                status: 'pending',
                dueDate: dueDate ? new Date(dueDate) : null,
                dueTime,
                categoryId,
                tags: tags || [],
                estimatedMinutes: estimatedMinutes || 0,
                isRecurring: isRecurring || false,
                recurringPattern,
                tokenReward: tokenReward || 10,
                xpReward: xpReward || 15
            },
            include: { subTasks: true, category: true }
        });

        res.status(201).json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateTask = async (req, res) => {
    try {
        const { id } = req.params;
        const existingTask = await prisma.task.findFirst({ where: { id, userId: req.user.id } });
        
        if (!existingTask) return res.status(404).json({ success: false, message: 'Task not found' });

        const dataToUpdate = { ...req.body };
        if (dataToUpdate.dueDate) dataToUpdate.dueDate = new Date(dataToUpdate.dueDate);
        
        const isNowCompleted = dataToUpdate.status === 'completed' && existingTask.status !== 'completed';

        if (isNowCompleted) {
            dataToUpdate.completedAt = new Date();
        } else if (dataToUpdate.status && dataToUpdate.status !== 'completed') {
            dataToUpdate.completedAt = null;
        }

        const task = await prisma.task.update({
            where: { id },
            data: dataToUpdate,
            include: { subTasks: true, category: true }
        });

        // Award token and XP rewards if task transitioned to completed
        if (isNowCompleted) {
            const tokenAmount = task.tokenReward || 10;
            const xpAmount = task.xpReward || 15;

            if (tokenAmount > 0) {
                await walletService.adjustBalance(
                    req.user.id,
                    tokenAmount,
                    'EARNED',
                    `Completed task: ${task.title}`,
                    task.id
                );
            }
            if (xpAmount > 0) {
                await petService.gainXp(req.user.id, xpAmount);
            }
        }

        res.json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteTask = async (req, res) => {
    try {
        const { id } = req.params;
        const task = await prisma.task.findFirst({ where: { id, userId: req.user.id } });
        
        if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

        await prisma.task.delete({ where: { id } });

        res.json({ success: true, message: 'Task deleted' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.completeTask = async (req, res) => {
    try {
        const { id } = req.params;
        const existingTask = await prisma.task.findFirst({ where: { id, userId: req.user.id } });

        if (!existingTask) return res.status(404).json({ success: false, message: 'Task not found' });

        if (existingTask.status === 'completed') {
            return res.json({ success: true, data: existingTask, message: 'Task already completed' });
        }

        const task = await prisma.task.update({
            where: { id },
            data: {
                status: 'completed',
                completedAt: new Date()
            },
            include: { subTasks: true, category: true }
        });

        // Award token and XP rewards via walletService & petService
        const tokenAmount = task.tokenReward || 10;
        const xpAmount = task.xpReward || 15;

        if (tokenAmount > 0) {
            await walletService.adjustBalance(
                req.user.id,
                tokenAmount,
                'EARNED',
                `Completed task: ${task.title}`,
                task.id
            );
        }
        if (xpAmount > 0) {
            await petService.gainXp(req.user.id, xpAmount);
        }

        res.json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
