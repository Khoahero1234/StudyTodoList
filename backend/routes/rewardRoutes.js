// backend/routes/rewardRoutes.js

const express = require('express');
const router = express.Router();
const rewardController = require('../controllers/rewardController');
const authMiddleware = require('../middleware/authMiddleware');

// All reward endpoints are protected by authMiddleware
router.use(authMiddleware);

// GET /api/rewards - Get active rewards list and login streak
router.get('/', rewardController.getRewards);

// POST /api/rewards/claim/:rewardId - Claim specific reward
router.post('/claim/:rewardId', rewardController.claimReward);

module.exports = router;
