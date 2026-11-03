const express = require('express');
const router = express.Router();

const verifyToken = require('../middleware/authMiddleware');
const requireAdmin = require('../middleware/adminMiddleware');

const productCtrl = require('../controllers/adminProductController');
const categoryCtrl = require('../controllers/adminCategoryController');
const userCtrl = require('../controllers/adminUserController');

// Áp dụng verifyToken + requireAdmin cho tất cả routes trong file này
router.use(verifyToken, requireAdmin);

// ─── Products ───────────────────────────────────────────────
router.get('/products', productCtrl.getAllProducts);
router.post('/products', productCtrl.createProduct);
router.put('/products/:id', productCtrl.updateProduct);
router.delete('/products/:id', productCtrl.deleteProduct);

// ─── Product Categories ──────────────────────────────────────
router.get('/categories', categoryCtrl.getAllCategories);
router.post('/categories', categoryCtrl.createCategory);
router.put('/categories/:id', categoryCtrl.updateCategory);
router.delete('/categories/:id', categoryCtrl.deleteCategory);

// ─── User Management ─────────────────────────────────────────
router.get('/users', userCtrl.getAllUsers);
router.patch('/users/:id/role', userCtrl.changeUserRole);
router.patch('/users/:id/ban', userCtrl.toggleUserBan);

module.exports = router;
