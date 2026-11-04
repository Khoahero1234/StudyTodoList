// backend/routes/orderRoutes.js

const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const authMiddleware = require('../middleware/authMiddleware');

router.use(authMiddleware);

router.post('/', orderController.createOrder);
router.get('/', orderController.getOrders);
router.get('/inventory', orderController.getInventory);
router.patch('/inventory/:id/equip', orderController.toggleEquipInventoryItem);

module.exports = router;
