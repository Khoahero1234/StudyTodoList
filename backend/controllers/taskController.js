const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

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
        const { title, description, priority, dueDate, dueTime, categoryId, tags, estimatedMinutes, isRecurring, recurringPattern } = req.body;
        
        const task = await prisma.task.create({
            data: {
                userId: req.user.id,
                title,
                description,
                priority: priority ? priority.toUpperCase() : 'MEDIUM',
                status: 'PENDING',
                dueDate: dueDate ? new Date(dueDate) : null,
                startTime: dueTime || null,
                categoryId,
                tags: tags || [],
                estimatedMinutes: estimatedMinutes || 0,
                isRecurring: isRecurring || false,
                recurringPattern,
                tokenReward: 5,
                xpReward: 10
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

        // Chi lay cac field hop le cua Prisma Task model (tranh unknown field error)
        const { title, description, priority, status, dueDate, dueTime, categoryId, projectId, tags, estimatedMinutes, isRecurring, recurringPattern } = req.body;

        const dataToUpdate = {};
        if (title !== undefined) dataToUpdate.title = title;
        if (description !== undefined) dataToUpdate.description = description;
        if (priority !== undefined) dataToUpdate.priority = priority.toUpperCase();
        if (status !== undefined) dataToUpdate.status = status.toUpperCase();
        if (dueDate !== undefined) dataToUpdate.dueDate = dueDate ? new Date(dueDate) : null;
        if (dueTime !== undefined) dataToUpdate.startTime = dueTime || null; // Flutter gui "dueTime", Prisma luu "startTime"
        if (categoryId !== undefined) dataToUpdate.categoryId = categoryId || null;
        if (projectId !== undefined) dataToUpdate.projectId = projectId || null;
        if (tags !== undefined) dataToUpdate.tags = tags;
        if (estimatedMinutes !== undefined) dataToUpdate.estimatedMinutes = estimatedMinutes;
        if (isRecurring !== undefined) dataToUpdate.isRecurring = isRecurring;
        if (recurringPattern !== undefined) dataToUpdate.recurringPattern = recurringPattern || null;

        // Xu ly completedAt khi doi status
        if (status === 'COMPLETED' && existingTask.status !== 'COMPLETED') {
            dataToUpdate.completedAt = new Date();
        } else if (status && status !== 'COMPLETED') {
            dataToUpdate.completedAt = null;
        }

        const task = await prisma.task.update({
            where: { id },
            data: dataToUpdate,
            include: { subTasks: true, category: true }
        });

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

        const task = await prisma.task.update({
            where: { id },
            data: {
                status: 'completed',
                completedAt: new Date()
            },
            include: { subTasks: true, category: true }
        });

        res.json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
