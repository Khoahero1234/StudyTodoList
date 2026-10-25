const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Helper to simulate push notification delivery
const sendPushNotification = async ({ userId, title, body, data }) => {
    console.log(`[PUSH NOTIFICATION] To User ${userId}: "${title}" - "${body}"`);
    // In production, integrate Firebase Cloud Messaging (FCM) or Expo Push API here
    return { success: true, timestamp: new Date() };
};

exports.sendPushNotification = sendPushNotification;

exports.getNotifications = async (req, res) => {
    try {
        const { isRead, page = 1, pageSize = 20 } = req.query;

        const where = { userId: req.user.id };
        if (isRead !== undefined) {
            where.isRead = isRead === 'true' || isRead === true;
        }

        const skip = (parseInt(page) - 1) * parseInt(pageSize);
        const take = parseInt(pageSize);

        const [notifications, total, unreadCount] = await Promise.all([
            prisma.notification.findMany({
                where,
                skip,
                take,
                orderBy: { createdAt: 'desc' },
                include: {
                    sender: {
                        select: { id: true, username: true, displayName: true, avatarUrl: true }
                    }
                }
            }),
            prisma.notification.count({ where }),
            prisma.notification.count({ where: { userId: req.user.id, isRead: false } })
        ]);

        res.json({
            success: true,
            data: notifications,
            meta: {
                total,
                unreadCount,
                page: parseInt(page),
                pageSize: take,
                totalPages: Math.ceil(total / take)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.markAsRead = async (req, res) => {
    try {
        const { id } = req.params;

        const notification = await prisma.notification.findFirst({
            where: { id, userId: req.user.id }
        });

        if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });

        const updated = await prisma.notification.update({
            where: { id },
            data: { isRead: true }
        });

        res.json({ success: true, data: updated });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.markAllAsRead = async (req, res) => {
    try {
        await prisma.notification.updateMany({
            where: { userId: req.user.id, isRead: false },
            data: { isRead: true }
        });

        res.json({ success: true, message: 'All notifications marked as read' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteNotification = async (req, res) => {
    try {
        const { id } = req.params;

        const notification = await prisma.notification.findFirst({
            where: { id, userId: req.user.id }
        });

        if (!notification) return res.status(404).json({ success: false, message: 'Notification not found' });

        await prisma.notification.delete({ where: { id } });

        res.json({ success: true, message: 'Notification deleted' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// ─── Task Reminders & Scheduled Alerts ───────────────────────────────

exports.createTaskReminder = async (req, res) => {
    try {
        const { taskId, minutesBefore } = req.body;

        if (!taskId || !minutesBefore) {
            return res.status(400).json({ success: false, message: 'taskId and minutesBefore are required' });
        }

        const task = await prisma.task.findFirst({
            where: { id: taskId, userId: req.user.id, deletedAt: null }
        });

        if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

        // Upsert TaskReminder
        const reminder = await prisma.taskReminder.upsert({
            where: {
                taskId_minutesBefore: {
                    taskId,
                    minutesBefore: parseInt(minutesBefore)
                }
            },
            update: {
                isSent: false
            },
            create: {
                taskId,
                userId: req.user.id,
                minutesBefore: parseInt(minutesBefore),
                isSent: false
            }
        });

        // Calculate scheduled time
        let scheduledAt = null;
        if (task.dueDate) {
            scheduledAt = new Date(task.dueDate.getTime() - parseInt(minutesBefore) * 60 * 1000);
        }

        // Create corresponding notification entry
        const notification = await prisma.notification.create({
            data: {
                userId: req.user.id,
                type: 'TASK_REMINDER',
                title: `Reminder: ${task.title}`,
                body: `Your task is due in ${minutesBefore} minutes!`,
                data: { taskId: task.id, minutesBefore: parseInt(minutesBefore) },
                scheduledAt
            }
        });

        // Simulate push delivery trigger
        sendPushNotification({
            userId: req.user.id,
            title: notification.title,
            body: notification.body,
            data: notification.data
        });

        res.status(201).json({
            success: true,
            data: {
                reminder,
                notification
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.getTaskReminders = async (req, res) => {
    try {
        const { taskId } = req.params;

        const reminders = await prisma.taskReminder.findMany({
            where: { taskId, userId: req.user.id },
            include: { task: true }
        });

        res.json({ success: true, data: reminders });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.deleteTaskReminder = async (req, res) => {
    try {
        const { id } = req.params;

        const reminder = await prisma.taskReminder.findFirst({
            where: { id, userId: req.user.id }
        });

        if (!reminder) return res.status(404).json({ success: false, message: 'Reminder not found' });

        await prisma.taskReminder.delete({ where: { id } });

        res.json({ success: true, message: 'Task reminder removed' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
