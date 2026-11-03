const express = require('express');
const router = express.Router();
const walletController = require('../controllers/walletController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.get('/', walletController.getWalletInfo);
router.get('/transactions', walletController.getTransactionHistory);

module.exports = router;
