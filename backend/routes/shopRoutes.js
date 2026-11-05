// backend/routes/shopRoutes.js

const express = require('express');
const router = express.Router();
const shopController = require('../controllers/shopController');
const orderController = require('../controllers/orderController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/products', shopController.getProducts);
router.get('/categories', shopController.getCategories);
router.get('/products/:id', shopController.getProductById);

// Các endpoint cần xác thực trực tiếp dưới /shop để tiện gọi từ client
router.post('/purchase', authMiddleware, orderController.createOrder);
router.get('/inventory', authMiddleware, orderController.getInventory);
router.patch('/inventory/:id/equip', authMiddleware, orderController.toggleEquipInventoryItem);

module.exports = router;
