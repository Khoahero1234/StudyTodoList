// controllers/studyRoomController.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Create a new study room
exports.createRoom = async (req, res) => {
  const { name, inviteCode, description } = req.body;
  const ownerId = req.user.id;
  try {
    const room = await prisma.studyRoom.create({
      data: {
        name,
        inviteCode,
        description,
        ownerId,
        status: 'ACTIVE'
      }
    });
    res.json({ success: true, data: room });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// List all study rooms (or those the user is a member of)
exports.listRooms = async (req, res) => {
  const userId = req.user.id;
  try {
    // Rooms where user is owner or member
    const rooms = await prisma.studyRoom.findMany({
      where: {
        OR: [
          { ownerId: userId },
          { members: { some: { userId } } }
        ]
      },
      include: { members: true }
    });
    res.json({ success: true, data: rooms });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// Join a study room by invite code or room id
exports.joinRoom = async (req, res) => {
  const roomId = parseInt(req.params.id, 10);
  const userId = req.user.id;
  try {
    // Ensure not already a member
    const existing = await prisma.studyRoomMember.findFirst({
      where: { roomId, userId }
    });
    if (existing) return res.status(400).json({ success: false, error: 'Already a member' });
    await prisma.studyRoomMember.create({ data: { roomId, userId } });
    res.json({ success: true, message: 'Joined room' });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// Leave a study room
exports.leaveRoom = async (req, res) => {
  const roomId = parseInt(req.params.id, 10);
  const userId = req.user.id;
  try {
    await prisma.studyRoomMember.deleteMany({
      where: { roomId, userId }
    });
    res.json({ success: true, message: 'Left room' });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// Get details of a specific study room
exports.getRoom = async (req, res) => {
  const roomId = parseInt(req.params.id, 10);
  try {
    const room = await prisma.studyRoom.findUnique({
      where: { id: roomId },
      include: { members: true }
    });
    if (!room) return res.status(404).json({ success: false, error: 'Room not found' });
    res.json({ success: true, data: room });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};
