/**
 * Admin Middleware
 * Phải dùng sau verifyToken.
 * Kiểm tra req.user.role === 'ADMIN', từ chối 403 nếu không phải.
 */
function requireAdmin(req, res, next) {
    if (!req.user) {
        return res.status(401).json({ success: false, message: 'Unauthorized' });
    }
    if (req.user.role !== 'ADMIN') {
        return res.status(403).json({ success: false, message: 'Forbidden: Admin only' });
    }
    next();
}

module.exports = requireAdmin;
