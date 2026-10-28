// controllers/friendController.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Send a friend request
exports.sendRequest = async (req, res) => {
  const { receiverId } = req.body;
  const requesterId = req.user.id;
  try {
    // Prevent duplicate requests or existing friendship
    const existing = await prisma.friendRequest.findFirst({
      where: {
        OR: [
          { requesterId, receiverId },
          { requesterId: receiverId, receiverId: requesterId }
        ],
        status: 'PENDING'
      }
    });
    if (existing) return res.status(400).json({ success: false, error: 'Friend request already pending' });

    const alreadyFriends = await prisma.friend.findFirst({
      where: {
        OR: [
          { userId: requesterId, friendId: receiverId },
          { userId: receiverId, friendId: requesterId }
        ]
      }
    });
    if (alreadyFriends) return res.status(400).json({ success: false, error: 'Already friends' });

    const request = await prisma.friendRequest.create({
      data: { requesterId, receiverId }
    });
    res.json({ success: true, data: request });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// Accept a friend request
exports.acceptRequest = async (req, res) => {
  const { requestId } = req.body;
  const userId = req.user.id;
  try {
    const request = await prisma.friendRequest.findUnique({ where: { id: requestId } });
    if (!request || request.receiverId !== userId) {
      return res.status(404).json({ success: false, error: 'Request not found' });
    }
    await prisma.$transaction(async (tx) => {
      await tx.friendRequest.update({
        where: { id: requestId },
        data: { status: 'ACCEPTED' }
      });
      // Create reciprocal friend rows
      await tx.friend.createMany({
        data: [
          { userId: request.requesterId, friendId: request.receiverId },
          { userId: request.receiverId, friendId: request.requesterId }
        ]
      });
    });
    res.json({ success: true, message: 'Friend added' });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// Reject a friend request
exports.rejectRequest = async (req, res) => {
  const { requestId } = req.body;
  const userId = req.user.id;
  try {
    const request = await prisma.friendRequest.findUnique({ where: { id: requestId } });
    if (!request || request.receiverId !== userId) {
      return res.status(404).json({ success: false, error: 'Request not found' });
    }
    await prisma.friendRequest.update({
      where: { id: requestId },
      data: { status: 'REJECTED' }
    });
    res.json({ success: true, message: 'Request rejected' });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// List friends of logged‑in user
exports.listFriends = async (req, res) => {
  const userId = req.user.id;
  try {
    const friends = await prisma.friend.findMany({
      where: { userId },
      include: { friend: true }
    });
    const result = friends.map(f => f.friend);
    res.json({ success: true, data: result });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// List incoming pending friend requests
exports.listIncomingRequests = async (req, res) => {
  const userId = req.user.id;
  try {
    const requests = await prisma.friendRequest.findMany({
      where: { receiverId: userId, status: 'PENDING' },
      include: { requester: true }
    });
    res.json({ success: true, data: requests });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};
