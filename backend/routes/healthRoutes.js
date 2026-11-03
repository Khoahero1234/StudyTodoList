// routes/healthRoutes.js
const express = require('express');
const router = express.Router();
const {
    basicHealth,
    checkDatabase,
    fullHealth,
} = require('../controllers/healthController');

// GET /health          → kiểm tra server
// GET /health/db       → kiểm tra kết nối database
// GET /health/full     → kiểm tra toàn diện (server + DB + số bản ghi)

router.get('/', basicHealth);
router.get('/db', checkDatabase);
router.get('/full', fullHealth);

module.exports = router;

