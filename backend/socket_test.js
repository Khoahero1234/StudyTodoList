// socket_test.js - verification test for Socket.IO server (TV3)
const { io } = require('socket.io-client');

const socket = io('http://localhost:3000', {
  transports: ['websocket'],
});

socket.on('connect', () => {
  console.log('✅ Connected to Socket.IO server, socket id:', socket.id);

  // 1. Join a test conversation
  const testConvId = 'test-conversation-uuid';
  socket.emit('chat:join', { conversationId: testConvId });

  // 2. Join a test study room
  const testRoomId = 'test-room-uuid';
  socket.emit('studyRoom:join', {
    roomId: testRoomId,
    user: { id: 'user-1', name: 'Student 1' }
  });

  // 3. Test study room message broadcast
  socket.emit('studyRoom:message', {
    roomId: testRoomId,
    senderId: 'user-1',
    senderName: 'Student 1',
    content: 'Hello study room members!'
  });
});

socket.on('chat:message', (msg) => {
  console.log('📨 Received chat:message from server:', msg);
});

socket.on('studyRoom:message', (msg) => {
  console.log('🏫 Received studyRoom:message from server:', msg);
});

socket.on('studyRoom:userJoined', (data) => {
  console.log('👋 User joined study room:', data);
});

socket.on('disconnect', () => {
  console.log('🔌 Disconnected');
});

socket.on('connect_error', (err) => {
  console.error('❌ Connection error:', err.message);
});
