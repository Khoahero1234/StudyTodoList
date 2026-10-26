// controllers/chatController.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Create a new conversation (direct or group)
exports.createConversation = async (req, res) => {
  const { participantIds, name, type = 'DIRECT' } = req.body; // participantIds: array of user IDs
  const creatorId = req.user.id;
  try {
    // For DIRECT, enforce exactly two participants (including creator)
    if (type === 'DIRECT' && participantIds.length !== 1) {
      return res.status(400).json({ success: false, error: 'Direct conversation requires exactly one other participant' });
    }
    const participants = [creatorId, ...participantIds];
    const conversation = await prisma.conversation.create({
      data: {
        name,
        type,
        avatarUrl: null,
        members: {
          create: participants.map(uid => ({ userId: uid }))
        }
      },
      include: { members: true }
    });
    res.json({ success: true, data: conversation });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// List conversations of logged‑in user
exports.listConversations = async (req, res) => {
  const userId = req.user.id;
  try {
    const memberships = await prisma.conversationMember.findMany({
      where: { userId },
      include: {
        conversation: {
          include: { members: true }
        }
      }
    });
    const conversations = memberships.map(m => m.conversation);
    res.json({ success: true, data: conversations });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// List messages of a conversation (paged)
exports.listMessages = async (req, res) => {
  const { id } = req.params; // conversationId
  const { page = 1, limit = 20 } = req.query;
  const skip = (page - 1) * limit;
  try {
    const messages = await prisma.message.findMany({
      where: { conversationId: id },
      orderBy: { createdAt: 'asc' },
      skip: Number(skip),
      take: Number(limit)
    });
    res.json({ success: true, data: messages });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};

// Delete a conversation (only allowed for group owners or participants)
exports.deleteConversation = async (req, res) => {
  const { id } = req.params; // conversationId
  const userId = req.user.id;
  try {
    // Verify user is a member
    const membership = await prisma.conversationMember.findFirst({
      where: { conversationId: id, userId }
    });
    if (!membership) return res.status(403).json({ success: false, error: 'Not a participant' });
    await prisma.conversation.delete({ where: { id } });
    res.json({ success: true, message: 'Conversation deleted' });
  } catch (e) {
    console.error(e);
    res.status(500).json({ success: false, error: 'Server error' });
  }
};
