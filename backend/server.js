const express = require('express');
const cors = require('cors');
<<<<<<< HEAD
const http = require('http');
const { Server } = require('socket.io');
const authRoutes = require('./routes/authRoutes');
const taskRoutes = require('./routes/taskRoutes');
const friendRoutes = require('./routes/friendRoutes');
const chatRoutes = require('./routes/chatRoutes');
const studyRoomRoutes = require('./routes/studyRoomRoutes');
=======

const authRoutes = require('./routes/authRoutes');
const taskRoutes = require('./routes/taskRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const goalRoutes = require('./routes/goalRoutes');
const projectRoutes = require('./routes/projectRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
>>>>>>> origin/main

const app = express();

app.use(cors());
app.use(express.json());

// Create HTTP server and attach Socket.IO
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

<<<<<<< HEAD
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
    // For now just broadcast; persistence can be added later
    io.to(`studyRoom_${roomId}`).emit('studyRoom:message', payload);
  });
});

// Use the same server instance for listening at the end of file

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/friends', friendRoutes);
app.use('/api/v1/chats', chatRoutes);
app.use('/api/v1/studyrooms', studyRoomRoutes);
=======
// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date() });
});

// API V1 Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/categories', categoryRoutes);
app.use('/api/v1/goals', goalRoutes);
app.use('/api/v1/projects', projectRoutes);
app.use('/api/v1/notifications', notificationRoutes);
>>>>>>> origin/main

// Global Error Handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: 'Internal Server Error' });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
