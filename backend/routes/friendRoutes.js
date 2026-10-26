// routes/friendRoutes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const friendController = require('../controllers/friendController');

// Send a friend request
router.post('/request', verifyToken, friendController.sendRequest);
// Accept a friend request
router.post('/accept', verifyToken, friendController.acceptRequest);
// Reject a friend request
router.post('/reject', verifyToken, friendController.rejectRequest);
// List friends of the logged‑in user
router.get('/list', verifyToken, friendController.listFriends);
// List incoming friend requests
router.get('/requests', verifyToken, friendController.listIncomingRequests);

module.exports = router;
