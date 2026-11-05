const express = require('express');
const router = express.Router();
const missionController = require('../controllers/missionController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/', missionController.getDailyMissions);
router.get('/daily', missionController.getDailyMissions);
router.post('/track', missionController.trackMissionActivity);
router.post('/generate-tasks', missionController.generateSampleTasks);

module.exports = router;
