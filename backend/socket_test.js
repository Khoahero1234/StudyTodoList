// socket_test.js - simple test for Socket.IO server
const { io } = require('socket.io-client');

const socket = io('http://localhost:3000', {
  transports: ['websocket'],
});

socket.on('connect', () => {
  console.log('✅ Connected to server, socket id:', socket.id);
  // Test chat message event
  socket.emit('chat:message', {
    conversationId: 1,
    senderId: 1,
    content: 'Hello from test client',
    type: 'TEXT',
  });
});

socket.on('chat:message', (msg) => {
  console.log('📨 Received chat message from server:', msg);
});

socket.on('disconnect', () => {
  console.log('🔌 Disconnected');
});

socket.on('connect_error', (err) => {
  console.error('❌ Connection error:', err.message);
});
