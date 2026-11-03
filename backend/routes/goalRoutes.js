const express = require('express');
const router = express.Router();
const goalController = require('../controllers/goalController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/', goalController.getGoals);
router.get('/:id', goalController.getGoalById);
router.post('/', goalController.createGoal);
router.patch('/:id', goalController.updateGoal);
router.delete('/:id', goalController.deleteGoal);

module.exports = router;
