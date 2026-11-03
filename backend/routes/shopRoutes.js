// backend/routes/shopRoutes.js

const express = require('express');
const router = express.Router();
const shopController = require('../controllers/shopController');

router.get('/products', shopController.getProducts);
router.get('/categories', shopController.getCategories);
router.get('/products/:id', shopController.getProductById);

module.exports = router;
