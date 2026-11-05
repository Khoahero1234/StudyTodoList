const express = require('express');
const router = express.Router();
const vnpayController = require('../controllers/vnpayController');
const authMiddleware = require('../middleware/authMiddleware');

// Endpoint lấy danh sách gói nạp (không cần login hoặc có login đều được)
router.get('/packages', vnpayController.getPackages);

// Endpoint tạo link thanh toán (bắt buộc login để gắn với user)
router.post('/create-payment-url', authMiddleware, vnpayController.createPaymentUrl);

// VNPay gọi về sau khi khách thanh toán xong (Return URL)
router.get('/vnpay-return', vnpayController.vnpayReturn);

// VNPay gọi IPN Webhook
router.get('/vnpay-ipn', vnpayController.vnpayIpn);

module.exports = router;
