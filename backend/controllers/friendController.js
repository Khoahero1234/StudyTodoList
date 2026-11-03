// controllers/friendController.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const userSelectFields = {
  id: true,
  username: true,
  displayName: true,
  email: true,
  avatarUrl: true,
};

function formatUser(u) {
  if (!u) return u;
  return {
    ...u,
    name: u.displayName || u.username || 'Người dùng',
  };
}

// Search users to add friend
exports.searchUsers = async (req, res) => {
  const userId = req.user?.id;
  const { q } = req.query;

  try {
    if (!q || !q.trim()) {
      return res.json({ success: true, data: [] });
    }
    const query = q.trim();

    const users = await prisma.user.findMany({
      where: {
        id: { not: userId },
        OR: [
          { username: { contains: query } },
          { displayName: { contains: query } },
          { email: { contains: query } },
        ],
      },
      select: userSelectFields,
      take: 20,
    });

    // Check relationship with logged-in user
    const friends = await prisma.friend.findMany({
      where: { userId },
    });
    const friendIdSet = new Set(friends.map((f) => f.friendId));

    const pendingRequests = await prisma.friendRequest.findMany({
      where: {
        OR: [
          { requesterId: userId, status: 'PENDING' },
          { receiverId: userId, status: 'PENDING' },
        ],
      },
    });

    const sentSet = new Set(
      pendingRequests.filter((r) => r.requesterId === userId).map((r) => r.receiverId)
    );
    const receivedSet = new Set(
      pendingRequests.filter((r) => r.receiverId === userId).map((r) => r.requesterId)
    );

    const result = users.map((u) => ({
      ...formatUser(u),
      isFriend: friendIdSet.has(u.id),
      isPendingSent: sentSet.has(u.id),
      isPendingReceived: receivedSet.has(u.id),
    }));

    res.json({ success: true, data: result });
  } catch (e) {
    console.error('Error searching users:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Send a friend request
exports.sendRequest = async (req, res) => {
  const { receiverId } = req.body;
  const requesterId = req.user?.id;

  try {
    if (!receiverId) {
      return res.status(400).json({ success: false, error: 'Thiếu receiverId' });
    }

    if (requesterId === receiverId) {
      return res.status(400).json({ success: false, error: 'Không thể kết bạn với chính mình' });
    }

    const receiver = await prisma.user.findUnique({ where: { id: receiverId } });
    if (!receiver) {
      return res.status(404).json({ success: false, error: 'Người dùng không tồn tại' });
    }

    const existing = await prisma.friendRequest.findFirst({
      where: {
        OR: [
          { requesterId, receiverId },
          { requesterId: receiverId, receiverId: requesterId },
        ],
        status: 'PENDING',
      },
    });
    if (existing) return res.status(400).json({ success: false, error: 'Lời mời kết bạn đang chờ phản hồi' });

    const alreadyFriends = await prisma.friend.findFirst({
      where: {
        OR: [
          { userId: requesterId, friendId: receiverId },
          { userId: receiverId, friendId: requesterId },
        ],
      },
    });
    if (alreadyFriends) return res.status(400).json({ success: false, error: 'Hai người đã là bạn bè' });

    const request = await prisma.friendRequest.create({
      data: { requesterId, receiverId },
    });

    res.json({ success: true, data: request, message: 'Đã gửi lời mời kết bạn' });
  } catch (e) {
    console.error('Error sending friend request:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Accept a friend request
exports.acceptRequest = async (req, res) => {
  const { requestId } = req.body;
  const userId = req.user?.id;

  try {
    if (!requestId) {
      return res.status(400).json({ success: false, error: 'Thiếu requestId' });
    }

    const request = await prisma.friendRequest.findUnique({ where: { id: requestId } });
    if (!request || request.receiverId !== userId) {
      return res.status(404).json({ success: false, error: 'Lời mời không tồn tại hoặc không dành cho bạn' });
    }

    await prisma.$transaction(async (tx) => {
      await tx.friendRequest.update({
        where: { id: requestId },
        data: { status: 'ACCEPTED' },
      });

      await tx.friend.upsert({
        where: { userId_friendId: { userId: request.requesterId, friendId: request.receiverId } },
        create: { userId: request.requesterId, friendId: request.receiverId },
        update: {},
      });
      await tx.friend.upsert({
        where: { userId_friendId: { userId: request.receiverId, friendId: request.requesterId } },
        create: { userId: request.receiverId, friendId: request.requesterId },
        update: {},
      });
    });

    res.json({ success: true, message: 'Đã chấp nhận lời mời kết bạn' });
  } catch (e) {
    console.error('Error accepting friend request:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Reject a friend request
exports.rejectRequest = async (req, res) => {
  const { requestId } = req.body;
  const userId = req.user?.id;

  try {
    if (!requestId) {
      return res.status(400).json({ success: false, error: 'Thiếu requestId' });
    }

    const request = await prisma.friendRequest.findUnique({ where: { id: requestId } });
    if (!request || request.receiverId !== userId) {
      return res.status(404).json({ success: false, error: 'Lời mời không tồn tại' });
    }

    await prisma.friendRequest.update({
      where: { id: requestId },
      data: { status: 'REJECTED' },
    });

    res.json({ success: true, message: 'Đã từ chối lời mời kết bạn' });
  } catch (e) {
    console.error('Error rejecting friend request:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// List friends of logged-in user
exports.listFriends = async (req, res) => {
  const userId = req.user?.id;

  try {
    const friends = await prisma.friend.findMany({
      where: { userId },
      include: {
        friend: {
          select: {
            id: true,
            username: true,
            displayName: true,
            email: true,
            avatarUrl: true,
            role: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const result = friends.map((f) => formatUser(f.friend));
    res.json({ success: true, data: result });
  } catch (e) {
    console.error('Error listing friends:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// List incoming pending friend requests
exports.listIncomingRequests = async (req, res) => {
  const userId = req.user?.id;

  try {
    const requests = await prisma.friendRequest.findMany({
      where: { receiverId: userId, status: 'PENDING' },
      include: {
        requester: {
          select: userSelectFields,
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const result = requests.map((r) => ({
      ...r,
      requester: formatUser(r.requester),
    }));

    res.json({ success: true, data: result });
  } catch (e) {
    console.error('Error listing friend requests:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Remove / unfriend
exports.removeFriend = async (req, res) => {
  const { friendId } = req.params;
  const userId = req.user?.id;

  try {
    await prisma.friend.deleteMany({
      where: {
        OR: [
          { userId, friendId },
          { userId: friendId, friendId: userId },
        ],
      },
    });

    res.json({ success: true, message: 'Đã hủy kết bạn' });
  } catch (e) {
    console.error('Error removing friend:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};
