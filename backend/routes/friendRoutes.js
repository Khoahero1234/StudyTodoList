// routes/friendRoutes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const friendController = require('../controllers/friendController');

// Search users
router.get('/search', verifyToken, friendController.searchUsers);
// Send a friend request
router.post('/request', verifyToken, friendController.sendRequest);
// Accept a friend request
router.post('/accept', verifyToken, friendController.acceptRequest);
// Reject a friend request
router.post('/reject', verifyToken, friendController.rejectRequest);
// List friends of the logged‑in user
router.get('/list', verifyToken, friendController.listFriends);
router.get('/', verifyToken, friendController.listFriends);
// List incoming friend requests
router.get('/requests', verifyToken, friendController.listIncomingRequests);
// Remove a friend
router.delete('/:friendId', verifyToken, friendController.removeFriend);

module.exports = router;
