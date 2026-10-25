const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const authMiddleware = require('../middleware/authMiddleware');

// Protect all task routes
router.use(authMiddleware);

// Task CRUD
router.get('/', taskController.getTasks);
router.get('/:id', taskController.getTaskById);
router.post('/', taskController.createTask);
router.patch('/:id', taskController.updateTask);
router.delete('/:id', taskController.deleteTask);
router.patch('/:id/complete', taskController.completeTask);

// Subtask endpoints
router.post('/:taskId/subtasks', taskController.createSubTask);
router.patch('/:taskId/subtasks/:subtaskId', taskController.updateSubTask);
router.delete('/:taskId/subtasks/:subtaskId', taskController.deleteSubTask);

module.exports = router;
