const express = require('express');
const router = express.Router();
const {
  startPomodoroSession,
  endPomodoroSession,
} = require('../controllers/pomodoroController');

// POST /api/v1/pomodoro/start
router.post('/start', startPomodoroSession);

// POST /api/v1/pomodoro/end
router.post('/end', endPomodoroSession);

module.exports = router;