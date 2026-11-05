// controllers/studyRoomController.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Helper to generate a random 6-character alphanumeric invite code
function generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

// Helper to format room and user names
function formatRoom(room) {
  if (!room) return room;
  return {
    ...room,
    owner: room.owner
      ? {
          ...room.owner,
          name: room.owner.displayName || room.owner.username || 'Chủ phòng',
        }
      : null,
    members: (room.members || []).map((m) => ({
      ...m,
      user: m.user
        ? {
            ...m.user,
            name: m.user.displayName || m.user.username || 'Thành viên',
          }
        : null,
    })),
  };
}

const userSelectFields = {
  id: true,
  username: true,
  displayName: true,
  avatarUrl: true,
};

// Create a new study room
exports.createRoom = async (req, res) => {
  const { name, description, maxParticipants = 10, isPrivate = false } = req.body;
  let inviteCode = req.body.inviteCode;
  const ownerId = req.user?.id;

  try {
    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, error: 'Tên phòng không được để trống' });
    }

    if (!inviteCode || !inviteCode.trim()) {
      inviteCode = generateInviteCode();
    } else {
      inviteCode = inviteCode.trim().toUpperCase();
    }

    const room = await prisma.studyRoom.create({
      data: {
        name: name.trim(),
        description: description ? description.trim() : null,
        inviteCode,
        ownerId,
        maxParticipants: Number(maxParticipants) || 10,
        isPrivate: Boolean(isPrivate),
        status: 'ACTIVE',
        members: {
          create: [{ userId: ownerId, isAdmin: true }],
        },
      },
      include: {
        owner: { select: userSelectFields },
        members: {
          include: {
            user: { select: userSelectFields },
          },
        },
      },
    });

    res.json({ success: true, data: formatRoom(room) });
  } catch (e) {
    console.error('Error creating study room:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// List all study rooms (public rooms or rooms user is participating in)
exports.listRooms = async (req, res) => {
  const userId = req.user?.id;
  try {
    const whereClause = userId
      ? {
          OR: [
            { status: 'ACTIVE', isPrivate: false },
            { ownerId: userId },
            { members: { some: { userId } } },
          ],
        }
      : { status: 'ACTIVE', isPrivate: false };

    const rooms = await prisma.studyRoom.findMany({
      where: whereClause,
      include: {
        owner: { select: userSelectFields },
        members: {
          include: {
            user: { select: userSelectFields },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ success: true, data: rooms.map(formatRoom) });
  } catch (e) {
    console.error('Error listing study rooms:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Join a study room by room id (UUID string)
exports.joinRoom = async (req, res) => {
  const roomId = req.params.id; // String UUID
  const userId = req.user?.id;

  try {
    const room = await prisma.studyRoom.findUnique({
      where: { id: roomId },
      include: { members: true },
    });

    if (!room) return res.status(404).json({ success: false, error: 'Phòng học không tồn tại' });

    if (room.members.length >= room.maxParticipants) {
      return res.status(400).json({ success: false, error: 'Phòng học đã đầy thành viên' });
    }

    const existing = await prisma.studyRoomMember.findFirst({
      where: { roomId, userId },
    });

    if (existing) {
      const fullRoom = await prisma.studyRoom.findUnique({
        where: { id: roomId },
        include: {
          owner: { select: userSelectFields },
          members: {
            include: { user: { select: userSelectFields } },
          },
        },
      });
      return res.json({ success: true, message: 'Đã ở trong phòng', data: formatRoom(fullRoom) });
    }

    await prisma.studyRoomMember.create({
      data: { roomId, userId, isAdmin: false },
    });

    const updatedRoom = await prisma.studyRoom.findUnique({
      where: { id: roomId },
      include: {
        owner: { select: userSelectFields },
        members: {
          include: {
            user: { select: userSelectFields },
          },
        },
      },
    });

    res.json({ success: true, message: 'Tham gia phòng thành công', data: formatRoom(updatedRoom) });
  } catch (e) {
    console.error('Error joining study room:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Join a study room by invite code
exports.joinByCode = async (req, res) => {
  const { inviteCode } = req.body;
  const userId = req.user?.id;

  try {
    if (!inviteCode || !inviteCode.trim()) {
      return res.status(400).json({ success: false, error: 'Mã mời không được để trống' });
    }

    const room = await prisma.studyRoom.findUnique({
      where: { inviteCode: inviteCode.trim().toUpperCase() },
      include: { members: true },
    });

    if (!room) return res.status(404).json({ success: false, error: 'Mã phòng học không tồn tại' });

    const existing = await prisma.studyRoomMember.findFirst({
      where: { roomId: room.id, userId },
    });

    if (!existing) {
      if (room.members.length >= room.maxParticipants) {
        return res.status(400).json({ success: false, error: 'Phòng học đã đạt giới hạn thành viên' });
      }

      await prisma.studyRoomMember.create({
        data: { roomId: room.id, userId, isAdmin: false },
      });
    }

    const updatedRoom = await prisma.studyRoom.findUnique({
      where: { id: room.id },
      include: {
        owner: { select: userSelectFields },
        members: {
          include: {
            user: { select: userSelectFields },
          },
        },
      },
    });

    res.json({ success: true, message: 'Tham gia phòng thành công', data: formatRoom(updatedRoom) });
  } catch (e) {
    console.error('Error joining study room by code:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Leave a study room
exports.leaveRoom = async (req, res) => {
  const roomId = req.params.id; // String UUID
  const userId = req.user?.id;

  try {
    await prisma.studyRoomMember.deleteMany({
      where: { roomId, userId },
    });

    res.json({ success: true, message: 'Đã rời phòng học' });
  } catch (e) {
    console.error('Error leaving study room:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Get details of a specific study room
exports.getRoom = async (req, res) => {
  const roomId = req.params.id; // String UUID

  try {
    const room = await prisma.studyRoom.findUnique({
      where: { id: roomId },
      include: {
        owner: { select: userSelectFields },
        members: {
          include: {
            user: { select: userSelectFields },
          },
        },
      },
    });

    if (!room) return res.status(404).json({ success: false, error: 'Không tìm thấy phòng học' });

    res.json({ success: true, data: formatRoom(room) });
  } catch (e) {
    console.error('Error fetching study room:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};
