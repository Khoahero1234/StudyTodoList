const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_key_for_dev';

function verifyToken(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ success: false, message: 'Unauthorized' });
    }
    const token = authHeader.split(' ')[1];
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded; // { id, username, email }
        next();
    } catch (e) {
        return res.status(401).json({ success: false, message: 'Invalid token' });
    }
}

// Export as default middleware function
module.exports = verifyToken;
// Also provide named export for destructuring imports
module.exports.verifyToken = verifyToken;
module.exports.verifyToken = verifyToken;
