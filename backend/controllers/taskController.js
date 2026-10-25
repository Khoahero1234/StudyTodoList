const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Helper to parse status enum
const parseStatus = (statusStr) => {
    if (!statusStr) return undefined;
    const s = statusStr.toUpperCase().replace('-', '_');
    if (s === 'INPROGRESS' || s === 'IN_PROGRESS') return 'IN_PROGRESS';
    if (s === 'PENDING') return 'PENDING';
    if (s === 'COMPLETED') return 'COMPLETED';
    if (s === 'CANCELLED') return 'CANCELLED';
    return undefined;
};

// Helper to parse priority enum
const parsePriority = (pStr) => {
    if (!pStr) return undefined;
    const p = pStr.toUpperCase();
    if (['LOW', 'MEDIUM', 'HIGH', 'URGENT'].includes(p)) return p;
    return undefined;
};

exports.getTasks = async (req, res) => {
    try {
        const {
            status,
            priority,
            search,
            categoryId,
            projectId,
            dueDateFrom,
            dueDateTo,
            isRecurring,
            sortBy = 'createdAt',
            sortOrder = 'desc',
            page = 1,
            pageSize = 20
        } = req.query;

        const where = {
            userId: req.user.id,
            deletedAt: null
        };

        const parsedStatus = parseStatus(status);
        if (parsedStatus) where.status = parsedStatus;

        const parsedPriority = parsePriority(priority);
        if (parsedPriority) where.priority = parsedPriority;

        if (categoryId) where.categoryId = categoryId;
        if (projectId) where.projectId = projectId;

        if (isRecurring !== undefined) {
            where.isRecurring = isRecurring === 'true' || isRecurring === true;
        }

        if (search) {
            where.OR = [
                { title: { contains: search, mode: 'insensitive' } },
                { description: { contains: search, mode: 'insensitive' } }
            ];
        }

        if (dueDateFrom || dueDateTo) {
            where.dueDate = {};
            if (dueDateFrom) where.dueDate.gte = new Date(dueDateFrom);
            if (dueDateTo) where.dueDate.lte = new Date(dueDateTo);
        }

        // Sorting configuration
        const validSortFields = ['dueDate', 'createdAt', 'updatedAt', 'priority', 'title'];
        const sortField = validSortFields.includes(sortBy) ? sortBy : 'createdAt';
        const sortDir = sortOrder.toLowerCase() === 'asc' ? 'asc' : 'desc';

        const skip = (parseInt(page) - 1) * parseInt(pageSize);
        const take = parseInt(pageSize);

        const [tasks, total] = await Promise.all([
            prisma.task.findMany({
                where,
                skip,
                take,
                orderBy: { [sortField]: sortDir },
                include: {
                    subTasks: {
                        orderBy: { sortOrder: 'asc' }
                    },
                    category: true,
                    project: true,
                    reminders: true
                }
            }),
            prisma.task.count({ where })
        ]);

        res.json({
            success: true,
            data: tasks,
            meta: {
                total,
                page: parseInt(page),
                pageSize: take,
                totalPages: Math.ceil(total / take)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getTaskById = async (req, res) => {
    try {
        const task = await prisma.task.findFirst({
            where: {
                id: req.params.id,
                userId: req.user.id,
                deletedAt: null
            },
            include: {
                subTasks: { orderBy: { sortOrder: 'asc' } },
                category: true,
                project: true,
                reminders: true
            }
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
            title,
            description,
            priority,
            dueDate,
            startTime,
            endTime,
            categoryId,
            projectId,
            tags,
            estimatedMinutes,
            isRecurring,
            recurringPattern,
            subTasks
        } = req.body;

        if (!title) {
            return res.status(400).json({ success: false, message: 'Title is required' });
        }

        const taskData = {
            userId: req.user.id,
            title,
            description,
            priority: parsePriority(priority) || 'MEDIUM',
            status: 'PENDING',
            dueDate: dueDate ? new Date(dueDate) : null,
            startTime,
            endTime,
            categoryId,
            projectId,
            tags: Array.isArray(tags) ? tags : [],
            estimatedMinutes: estimatedMinutes ? parseInt(estimatedMinutes) : 0,
            isRecurring: Boolean(isRecurring),
            recurringPattern,
            tokenReward: 5,
            xpReward: 10
        };

        if (Array.isArray(subTasks) && subTasks.length > 0) {
            taskData.subTasks = {
                create: subTasks.map((st, idx) => ({
                    title: typeof st === 'string' ? st : st.title,
                    isCompleted: st.isCompleted || false,
                    sortOrder: st.sortOrder || idx
                }))
            };
        }

        const task = await prisma.task.create({
            data: taskData,
            include: {
                subTasks: true,
                category: true,
                project: true
            }
        });

        res.status(201).json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateTask = async (req, res) => {
    try {
        const { id } = req.params;
        const existingTask = await prisma.task.findFirst({
            where: { id, userId: req.user.id, deletedAt: null }
        });

        if (!existingTask) return res.status(404).json({ success: false, message: 'Task not found' });

        const dataToUpdate = {};
        const {
            title,
            description,
            priority,
            status,
            dueDate,
            startTime,
            endTime,
            categoryId,
            projectId,
            tags,
            estimatedMinutes,
            actualMinutes,
            isRecurring,
            recurringPattern,
            subTasks
        } = req.body;

        if (title !== undefined) dataToUpdate.title = title;
        if (description !== undefined) dataToUpdate.description = description;
        if (priority !== undefined) dataToUpdate.priority = parsePriority(priority) || existingTask.priority;

        if (status !== undefined) {
            const parsedStatus = parseStatus(status);
            if (parsedStatus) {
                dataToUpdate.status = parsedStatus;
                if (parsedStatus === 'COMPLETED' && existingTask.status !== 'COMPLETED') {
                    dataToUpdate.completedAt = new Date();
                } else if (parsedStatus !== 'COMPLETED') {
                    dataToUpdate.completedAt = null;
                }
            }
        }

        if (dueDate !== undefined) dataToUpdate.dueDate = dueDate ? new Date(dueDate) : null;
        if (startTime !== undefined) dataToUpdate.startTime = startTime;
        if (endTime !== undefined) dataToUpdate.endTime = endTime;
        if (categoryId !== undefined) dataToUpdate.categoryId = categoryId;
        if (projectId !== undefined) dataToUpdate.projectId = projectId;
        if (tags !== undefined) dataToUpdate.tags = Array.isArray(tags) ? tags : [];
        if (estimatedMinutes !== undefined) dataToUpdate.estimatedMinutes = parseInt(estimatedMinutes) || 0;
        if (actualMinutes !== undefined) dataToUpdate.actualMinutes = parseInt(actualMinutes) || 0;
        if (isRecurring !== undefined) dataToUpdate.isRecurring = Boolean(isRecurring);
        if (recurringPattern !== undefined) dataToUpdate.recurringPattern = recurringPattern;

        // If subtasks are passed in body, replace or update
        if (Array.isArray(subTasks)) {
            // Delete existing subtasks and recreate
            await prisma.subTask.deleteMany({ where: { taskId: id } });
            dataToUpdate.subTasks = {
                create: subTasks.map((st, idx) => ({
                    title: typeof st === 'string' ? st : st.title,
                    isCompleted: st.isCompleted || false,
                    sortOrder: st.sortOrder || idx
                }))
            };
        }

        const task = await prisma.task.update({
            where: { id },
            data: dataToUpdate,
            include: {
                subTasks: { orderBy: { sortOrder: 'asc' } },
                category: true,
                project: true
            }
        });

        res.json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteTask = async (req, res) => {
    try {
        const { id } = req.params;
        const task = await prisma.task.findFirst({
            where: { id, userId: req.user.id, deletedAt: null }
        });

        if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

        // Soft delete
        await prisma.task.update({
            where: { id },
            data: { deletedAt: new Date() }
        });

        res.json({ success: true, message: 'Task deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.completeTask = async (req, res) => {
    try {
        const { id } = req.params;
        const existingTask = await prisma.task.findFirst({
            where: { id, userId: req.user.id, deletedAt: null }
        });

        if (!existingTask) return res.status(404).json({ success: false, message: 'Task not found' });

        const isNowCompleted = existingTask.status !== 'COMPLETED';
        const newStatus = isNowCompleted ? 'COMPLETED' : 'PENDING';

        const task = await prisma.task.update({
            where: { id },
            data: {
                status: newStatus,
                completedAt: isNowCompleted ? new Date() : null
            },
            include: {
                subTasks: true,
                category: true,
                project: true
            }
        });

        // Award rewards if task was newly completed
        if (isNowCompleted) {
            await prisma.user.update({
                where: { id: req.user.id },
                data: {
                    xp: { increment: task.xpReward || 10 }
                }
            });

            // Add tokens to wallet if available
            await prisma.wallet.updateMany({
                where: { userId: req.user.id },
                data: { balance: { increment: task.tokenReward || 5 } }
            });

            // If task is recurring, automatically spawn next recurring task
            if (task.isRecurring && task.recurringPattern) {
                let nextDueDate = task.dueDate ? new Date(task.dueDate) : new Date();
                const pattern = task.recurringPattern.toUpperCase();
                if (pattern.includes('DAILY')) {
                    nextDueDate.setDate(nextDueDate.getDate() + 1);
                } else if (pattern.includes('WEEKLY')) {
                    nextDueDate.setDate(nextDueDate.getDate() + 7);
                } else if (pattern.includes('MONTHLY')) {
                    nextDueDate.setMonth(nextDueDate.getMonth() + 1);
                } else {
                    nextDueDate.setDate(nextDueDate.getDate() + 1);
                }

                await prisma.task.create({
                    data: {
                        userId: req.user.id,
                        title: task.title,
                        description: task.description,
                        priority: task.priority,
                        status: 'PENDING',
                        dueDate: nextDueDate,
                        startTime: task.startTime,
                        endTime: task.endTime,
                        categoryId: task.categoryId,
                        projectId: task.projectId,
                        tags: task.tags,
                        estimatedMinutes: task.estimatedMinutes,
                        isRecurring: true,
                        recurringPattern: task.recurringPattern,
                        tokenReward: task.tokenReward,
                        xpReward: task.xpReward
                    }
                });
            }
        }

        res.json({ success: true, data: task });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─── Subtasks ────────────────────────────────────────────────────────

exports.createSubTask = async (req, res) => {
    try {
        const { taskId } = req.params;
        const { title, sortOrder } = req.body;

        if (!title) return res.status(400).json({ success: false, message: 'Subtask title is required' });

        const task = await prisma.task.findFirst({
            where: { id: taskId, userId: req.user.id, deletedAt: null }
        });

        if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

        const subTask = await prisma.subTask.create({
            data: {
                taskId,
                title,
                sortOrder: sortOrder || 0
            }
        });

        res.status(201).json({ success: true, data: subTask });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.updateSubTask = async (req, res) => {
    try {
        const { taskId, subtaskId } = req.params;
        const { title, isCompleted, sortOrder } = req.body;

        const task = await prisma.task.findFirst({
            where: { id: taskId, userId: req.user.id, deletedAt: null }
        });

        if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

        const dataToUpdate = {};
        if (title !== undefined) dataToUpdate.title = title;
        if (isCompleted !== undefined) dataToUpdate.isCompleted = Boolean(isCompleted);
        if (sortOrder !== undefined) dataToUpdate.sortOrder = parseInt(sortOrder);

        const subTask = await prisma.subTask.update({
            where: { id: subtaskId },
            data: dataToUpdate
        });

        res.json({ success: true, data: subTask });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteSubTask = async (req, res) => {
    try {
        const { taskId, subtaskId } = req.params;

        const task = await prisma.task.findFirst({
            where: { id: taskId, userId: req.user.id, deletedAt: null }
        });

        if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

        await prisma.subTask.delete({ where: { id: subtaskId } });

        res.json({ success: true, message: 'Subtask deleted successfully' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
