// controllers/chatController.js
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

function formatConversation(c) {
  if (!c) return c;
  return {
    ...c,
    members: (c.members || []).map((m) => ({
      ...m,
      user: formatUser(m.user),
    })),
  };
}

function formatMessage(m) {
  if (!m) return m;
  return {
    ...m,
    sender: formatUser(m.sender),
  };
}

// Create a new conversation (direct or group)
exports.createConversation = async (req, res) => {
  const { participantIds, name, type = 'DIRECT' } = req.body;
  const creatorId = req.user?.id;
  try {
    if (!participantIds || !Array.isArray(participantIds) || participantIds.length === 0) {
      return res.status(400).json({ success: false, error: 'Cần ít nhất một thành viên tham gia' });
    }

    // For DIRECT, check if conversation already exists between these 2 users
    if (type === 'DIRECT') {
      const otherId = participantIds[0];
      const existing = await prisma.conversation.findFirst({
        where: {
          type: 'DIRECT',
          AND: [
            { members: { some: { userId: creatorId } } },
            { members: { some: { userId: otherId } } },
          ],
        },
        include: {
          members: {
            include: {
              user: { select: userSelectFields },
            },
          },
        },
      });
      if (existing) {
        return res.json({ success: true, data: formatConversation(existing) });
      }
    }

    const allParticipantIds = Array.from(new Set([creatorId, ...participantIds]));
    const conversation = await prisma.conversation.create({
      data: {
        name: type === 'GROUP' ? (name || 'Nhóm học tập') : null,
        type,
        avatarUrl: null,
        members: {
          create: allParticipantIds.map((uid) => ({
            userId: uid,
            isAdmin: uid === creatorId,
          })),
        },
      },
      include: {
        members: {
          include: {
            user: { select: userSelectFields },
          },
        },
      },
    });

    res.json({ success: true, data: formatConversation(conversation) });
  } catch (e) {
    console.error('Error creating conversation:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// List conversations of logged-in user
exports.listConversations = async (req, res) => {
  const userId = req.user?.id;
  try {
    const memberships = await prisma.conversationMember.findMany({
      where: { userId },
      include: {
        conversation: {
          include: {
            members: {
              include: {
                user: { select: userSelectFields },
              },
            },
          },
        },
      },
      orderBy: {
        conversation: { updatedAt: 'desc' },
      },
    });

    const conversations = memberships.map((m) => formatConversation(m.conversation));
    res.json({ success: true, data: conversations });
  } catch (e) {
    console.error('Error listing conversations:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// List messages of a conversation (paged)
exports.listMessages = async (req, res) => {
  const { id } = req.params;
  const { page = 1, limit = 50 } = req.query;
  const skip = (page - 1) * limit;
  try {
    const messages = await prisma.message.findMany({
      where: { conversationId: id },
      include: {
        sender: {
          select: { id: true, username: true, displayName: true, avatarUrl: true },
        },
      },
      orderBy: { createdAt: 'asc' },
      skip: Number(skip),
      take: Number(limit),
    });
    res.json({ success: true, data: messages.map(formatMessage) });
  } catch (e) {
    console.error('Error listing messages:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Send message via REST API
exports.sendMessage = async (req, res) => {
  const { id } = req.params;
  const { content, type = 'TEXT' } = req.body;
  const senderId = req.user?.id;
  try {
    if (!content || !content.trim()) {
      return res.status(400).json({ success: false, error: 'Nội dung tin nhắn không được để trống' });
    }

    const message = await prisma.message.create({
      data: {
        conversationId: id,
        senderId,
        content: content.trim(),
        type,
      },
      include: {
        sender: { select: { id: true, username: true, displayName: true, avatarUrl: true } },
      },
    });

    await prisma.conversation
      .update({
        where: { id },
        data: { lastMessage: content.trim(), lastMessageAt: new Date() },
      })
      .catch(() => {});

    const formatted = formatMessage(message);

    if (global.io) {
      global.io.to(`conversation_${id}`).emit('chat:message', formatted);
    }

    res.json({ success: true, data: formatted });
  } catch (e) {
    console.error('Error sending message:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};

// Delete a conversation
exports.deleteConversation = async (req, res) => {
  const { id } = req.params;
  const userId = req.user?.id;
  try {
    const membership = await prisma.conversationMember.findFirst({
      where: { conversationId: id, userId },
    });
    if (!membership) return res.status(403).json({ success: false, error: 'Không có quyền truy cập' });
    await prisma.conversation.delete({ where: { id } });
    res.json({ success: true, message: 'Đã xóa cuộc trò chuyện' });
  } catch (e) {
    console.error('Error deleting conversation:', e);
    res.status(500).json({ success: false, error: e.message || 'Server error' });
  }
};
