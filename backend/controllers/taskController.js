const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const walletService = require('../services/walletService');
const petService = require('../services/petService');
const missionService = require('../services/missionService');

exports.getTasks = async (req, res) => {
    try {
        const { status, priority, search, categoryId, page = 1, pageSize = 20 } = req.query;

        // Tự động tạo các task học tập mẫu nếu tài khoản mới chưa có task nào
        if (!status && !priority && !search && !categoryId && Number(page) === 1) {
            await missionService.ensureDailyStudyTasks(req.user.id, false);
        }

        // Map lowercase flutter values to Prisma UPPERCASE enum
        const statusMap = { pending: 'PENDING', in_progress: 'IN_PROGRESS', inprogress: 'IN_PROGRESS', completed: 'COMPLETED', cancelled: 'CANCELLED' };
        const priorityMap = { low: 'LOW', medium: 'MEDIUM', high: 'HIGH', urgent: 'URGENT' };
        const where = { userId: req.user.id };
        if (status) where.status = statusMap[status.toLowerCase()] || status.toUpperCase();
        if (priority) where.priority = priorityMap[priority.toLowerCase()] || priority.toUpperCase();
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
        const {
            title, description, priority, dueDate, dueTime,
            categoryId, tags, estimatedMinutes, isRecurring,
            recurringPattern, tokenReward, xpReward
        } = req.body;

        const task = await prisma.task.create({
            data: {
                userId: req.user.id,
                title,
                description,
                priority: priority ? priority.toUpperCase() : 'MEDIUM',
                status: 'PENDING',
                dueDate: dueDate ? new Date(dueDate) : new Date(),
                startTime: dueTime || null,
                categoryId: categoryId || null,
                tags: tags || [],
                estimatedMinutes: estimatedMinutes || 20,
                isRecurring: isRecurring || false,
                recurringPattern,
                tokenReward: tokenReward || 15,
                xpReward: xpReward || 20
            },
            include: { subTasks: true, category: true }
        });

        res.status(201).json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

async function handleTaskCompletionRewards(userId, task) {
    const tokenAmount = task.tokenReward || 15;
    const xpAmount = task.xpReward || 20;

    const taskRefId = `task:${task.id}`;
    let alreadyAwarded = false;

    if (tokenAmount > 0) {
        const result = await walletService.adjustBalance(
            userId,
            tokenAmount,
            'REWARD',
            `Hoàn thành công việc: ${task.title}`,
            taskRefId
        );
        alreadyAwarded = Boolean(result && result.alreadyAwarded);
    }

    if (!alreadyAwarded) {
        if (xpAmount > 0) {
            try {
                await petService.gainXp(userId, xpAmount);
            } catch (_) {}
        }

        // Cập nhật thống kê ngày (tasksCompleted + focusMinutes)
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        await prisma.productivityStatistic.upsert({
            where: {
                userId_date: {
                    userId,
                    date: today
                }
            },
            update: {
                tasksCompleted: { increment: 1 },
                focusMinutes: { increment: task.estimatedMinutes || 15 }
            },
            create: {
                userId,
                date: today,
                tasksCompleted: 1,
                focusMinutes: task.estimatedMinutes || 15
            }
        });
    }

    // Tự động kiểm tra và cộng thưởng các nhiệm vụ tự động hàng ngày (Daily Automated Missions)
    const missionResult = await missionService.evaluateAndAutoRewardMissions(userId);
    return missionResult;
}

exports.updateTask = async (req, res) => {
    try {
        const { id } = req.params;
        const existingTask = await prisma.task.findFirst({ where: { id, userId: req.user.id } });

        if (!existingTask) return res.status(404).json({ success: false, message: 'Task not found' });

        const { title, description, priority, status, dueDate, dueTime, categoryId, projectId, tags, estimatedMinutes, isRecurring, recurringPattern } = req.body;

        const dataToUpdate = {};
        if (title !== undefined) dataToUpdate.title = title;
        if (description !== undefined) dataToUpdate.description = description;
        if (priority !== undefined) dataToUpdate.priority = priority.toUpperCase();
        if (status !== undefined) dataToUpdate.status = status.toUpperCase();
        if (dueDate !== undefined) dataToUpdate.dueDate = dueDate ? new Date(dueDate) : null;
        if (dueTime !== undefined) dataToUpdate.startTime = dueTime || null;
        if (categoryId !== undefined) dataToUpdate.categoryId = categoryId || null;
        if (projectId !== undefined) dataToUpdate.projectId = projectId || null;
        if (tags !== undefined) dataToUpdate.tags = tags;
        if (estimatedMinutes !== undefined) dataToUpdate.estimatedMinutes = estimatedMinutes;
        if (isRecurring !== undefined) dataToUpdate.isRecurring = isRecurring;
        if (recurringPattern !== undefined) dataToUpdate.recurringPattern = recurringPattern || null;

        const normalizedStatus = status ? status.toUpperCase() : undefined;
        if (existingTask.status === 'COMPLETED' && normalizedStatus && normalizedStatus !== 'COMPLETED') {
            return res.status(400).json({ success: false, message: 'Nhiệm vụ đã hoàn thành không thể chuyển về trạng thái chưa hoàn thành.' });
        }
        const isNowCompleted = normalizedStatus === 'COMPLETED' && existingTask.status !== 'COMPLETED';

        if (isNowCompleted) {
            dataToUpdate.completedAt = new Date();
        } else if (normalizedStatus && normalizedStatus !== 'COMPLETED') {
            dataToUpdate.completedAt = null;
        }

        const task = await prisma.task.update({
            where: { id },
            data: dataToUpdate,
            include: { subTasks: true, category: true }
        });

        let missionEvaluation = null;
        if (isNowCompleted) {
            missionEvaluation = await handleTaskCompletionRewards(req.user.id, task);
        }

        res.json({
            success: true,
            data: task,
            missionEvaluation
        });
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

        if (existingTask.status === 'COMPLETED') {
            return res.json({ success: true, data: existingTask, message: 'Task already completed' });
        }

        const task = await prisma.task.update({
            where: { id },
            data: {
                status: 'COMPLETED',
                completedAt: new Date()
            },
            include: { subTasks: true, category: true }
        });

        const missionEvaluation = await handleTaskCompletionRewards(req.user.id, task);

        res.json({
            success: true,
            data: task,
            missionEvaluation
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
