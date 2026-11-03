// routes/studyRoomRoutes.js
const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/authMiddleware');
const studyRoomController = require('../controllers/studyRoomController');

// Create a new study room
router.post('/', verifyToken, studyRoomController.createRoom);
// List all study rooms (or those the user is a member of)
router.get('/', verifyToken, studyRoomController.listRooms);
// Join a study room by invite code
router.post('/join-by-code', verifyToken, studyRoomController.joinByCode);
// Join a study room by id
router.post('/:id/join', verifyToken, studyRoomController.joinRoom);
// Leave a study room
router.post('/:id/leave', verifyToken, studyRoomController.leaveRoom);
// Get details of a study room
router.get('/:id', verifyToken, studyRoomController.getRoom);

module.exports = router;
