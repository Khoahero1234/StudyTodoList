require('dotenv').config();

const express = require('express');
const cors = require('cors');

const http = require('http');
const { Server } = require('socket.io');

const authRoutes = require('./routes/authRoutes');
const taskRoutes = require('./routes/taskRoutes');
const walletRoutes = require('./routes/walletRoutes');
const shopRoutes = require('./routes/shopRoutes');
const orderRoutes = require('./routes/orderRoutes');
const rewardRoutes = require('./routes/rewardRoutes');
const friendRoutes = require('./routes/friendRoutes');
const chatRoutes = require('./routes/chatRoutes');
const studyRoomRoutes = require('./routes/studyRoomRoutes');

const categoryRoutes = require('./routes/categoryRoutes');
const goalRoutes = require('./routes/goalRoutes');
const projectRoutes = require('./routes/projectRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

const aiRoutes = require('./routes/aiRoutes');
const pomodoroRoutes = require('./routes/pomodoroRoutes');
const statsRoutes = require('./routes/statsRoutes');
const missionRoutes = require('./routes/missionRoutes');
const healthRoutes = require('./routes/healthRoutes');

const { initStreakCron } = require('./services/streakCron');

initStreakCron();

const app = express();

app.use(cors({
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json());

// Basic logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Create HTTP server and attach Socket.IO
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});
global.io = io;

// Basic Socket.IO event handling
io.on('connection', (socket) => {
  console.log('🔌 Socket connected:', socket.id);

  // Chat message forwarding
  socket.on('chat:message', async (payload) => {
    const { conversationId, senderId, content, type = 'TEXT' } = payload;
    try {
      const message = await prisma.message.create({
        data: { conversationId, senderId, content, type },
        include: {
          sender: { select: { id: true, username: true, displayName: true, avatarUrl: true } }
        }
      });
      const formattedMessage = {
        ...message,
        sender: message.sender ? {
          ...message.sender,
          name: message.sender.displayName || message.sender.username || 'Người dùng'
        } : null
      };
      // Update conversation lastMessage
      await prisma.conversation.update({
        where: { id: conversationId },
        data: { lastMessage: content, lastMessageAt: new Date() }
      }).catch(() => {});

      // Emit to all participants in the conversation room
      io.to(`conversation_${conversationId}`).emit('chat:message', formattedMessage);
    } catch (e) {
      console.error('Error saving chat message:', e);
    }
  });

  // Join/leave conversation room for real-time updates
  socket.on('chat:join', ({ conversationId }) => {
    socket.join(`conversation_${conversationId}`);
  });
  socket.on('chat:leave', ({ conversationId }) => {
    socket.leave(`conversation_${conversationId}`);
  });

  // Study room events
  socket.on('studyRoom:join', ({ roomId, user }) => {
    socket.join(`studyRoom_${roomId}`);
    if (user) {
      io.to(`studyRoom_${roomId}`).emit('studyRoom:userJoined', { roomId, user });
    }
  });
  socket.on('studyRoom:leave', ({ roomId, userId }) => {
    socket.leave(`studyRoom_${roomId}`);
    if (userId) {
      io.to(`studyRoom_${roomId}`).emit('studyRoom:userLeft', { roomId, userId });
    }
  });
  socket.on('studyRoom:message', async (payload) => {
    const { roomId, senderId, senderName, content } = payload;
    const msgData = {
      id: Date.now().toString(),
      roomId,
      senderId,
      senderName: senderName || 'Member',
      content,
      createdAt: new Date().toISOString()
    };
    io.to(`studyRoom_${roomId}`).emit('studyRoom:message', msgData);
  });
  socket.on('studyRoom:toggleMedia', (data) => {
    const { roomId } = data;
    io.to(`studyRoom_${roomId}`).emit('studyRoom:mediaChanged', data);
  });
  socket.on('studyRoom:raiseHand', (data) => {
    const { roomId } = data;
    io.to(`studyRoom_${roomId}`).emit('studyRoom:handRaised', data);
  });
});

// Health check routes
app.use('/health', healthRoutes);

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/friends', friendRoutes);
app.use('/api/v1/chats', chatRoutes);
app.use('/api/v1/conversations', chatRoutes);
app.use('/api/v1/studyrooms', studyRoomRoutes);
app.use('/api/v1/study-rooms', studyRoomRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/pomodoro', pomodoroRoutes);
app.use('/api/v1/stats', statsRoutes);
app.use('/api/v1/missions', missionRoutes);
app.use('/api/v1/wallet', walletRoutes);
app.use('/api/v1/shop', shopRoutes);
app.use('/api/shop', shopRoutes);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/v1/rewards', rewardRoutes);
app.use('/api/rewards', rewardRoutes);

// Global Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`🩺 Health check: http://localhost:${PORT}/health`);
  console.log(`🗄️  DB check:     http://localhost:${PORT}/health/db`);
  console.log(`📊 Full check:   http://localhost:${PORT}/health/full`);
});
