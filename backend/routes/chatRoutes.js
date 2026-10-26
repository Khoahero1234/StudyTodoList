// routes/chatRoutes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const chatController = require('../controllers/chatController');

// Create a new conversation (direct or group)
router.post('/conversations', verifyToken, chatController.createConversation);
// Get conversations of logged‑in user
router.get('/conversations', verifyToken, chatController.listConversations);
// Get messages of a conversation (paged)
router.get('/conversations/:id/messages', verifyToken, chatController.listMessages);
// Delete a conversation (owner only for group)
router.delete('/conversations/:id', verifyToken, chatController.deleteConversation);

module.exports = router;
