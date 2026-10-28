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
const aiRoutes = require('./routes/aiRoutes');
const pomodoroRoutes = require('./routes/pomodoroRoutes');
const statsRoutes = require('./routes/statsRoutes');
const missionRoutes = require('./routes/missionRoutes');

const { initStreakCron } = require('./services/streakCron');

initStreakCron();

const app = express();

app.use(cors());
app.use(express.json());

// Basic logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});

// Create HTTP server and attach Socket.IO
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

// Basic Socket.IO event handling
io.on('connection', (socket) => {
  console.log('🔌 Socket connected:', socket.id);

  // Chat message forwarding
  socket.on('chat:message', async (payload) => {
    const { conversationId, senderId, content, type = 'TEXT' } = payload;
    // Persist message
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();
    try {
      const message = await prisma.message.create({
        data: { conversationId, senderId, content, type }
      });
      // Emit to all participants in the conversation room
      io.to(`conversation_${conversationId}`).emit('chat:message', message);
    } catch (e) {
      console.error('Error saving chat message', e);
    }
  });

  // Join conversation room for real‑time updates
  socket.on('chat:join', ({ conversationId }) => {
    socket.join(`conversation_${conversationId}`);
  });

  // Study room events
  socket.on('studyRoom:join', ({ roomId }) => {
    socket.join(`studyRoom_${roomId}`);
  });
  socket.on('studyRoom:leave', ({ roomId }) => {
    socket.leave(`studyRoom_${roomId}`);
  });
  socket.on('studyRoom:message', async (payload) => {
    const { roomId, senderId, content } = payload;
    io.to(`studyRoom_${roomId}`).emit('studyRoom:message', payload);
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date() });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/friends', friendRoutes);
app.use('/api/v1/chats', chatRoutes);
app.use('/api/v1/studyrooms', studyRoomRoutes);
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
});
