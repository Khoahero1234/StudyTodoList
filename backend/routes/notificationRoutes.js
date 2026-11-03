const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

// Notifications
router.get('/', notificationController.getNotifications);
router.patch('/read-all', notificationController.markAllAsRead);
router.patch('/:id/read', notificationController.markAsRead);
router.delete('/:id', notificationController.deleteNotification);

// Task Reminders
router.post('/reminders', notificationController.createTaskReminder);
router.get('/reminders/task/:taskId', notificationController.getTaskReminders);
router.delete('/reminders/:id', notificationController.deleteTaskReminder);

module.exports = router;
