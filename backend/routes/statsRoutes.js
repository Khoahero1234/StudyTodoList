const express = require('express');
const router = express.Router();
const { getWeeklyStats } = require('../controllers/statsController');

// GET /api/v1/stats/weekly/:userId
router.get('/weekly/:userId', getWeeklyStats);

module.exports = router;