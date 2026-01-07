/**
 * Gaming Social App - API Server
 * Main entry point for the Express server with Socket.IO
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const rateLimit = require('express-rate-limit');
const apiRoutes = require('./routes/api');
const postsRoutes = require('./routes/postsRoutes');
const redisConfig = require('./config/redis');

// Initialize Express app
const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;

// Initialize Socket.IO with CORS
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

/**
 * Middleware Configuration
 */

// Enable CORS for all origins (development)
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Parse JSON bodies
app.use(express.json());

// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

/**
 * Rate Limiting (Security)
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // 20 requests per window for auth
  message: { success: false, error: 'Too many attempts, try again later' }
});

const generalLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100 // 100 requests per minute
});

app.use(generalLimiter);
app.use('/api/auth', authLimiter);

/**
 * Routes
 */

// API routes
app.use('/api', apiRoutes);
app.use('/api/posts', postsRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'Gaming Social API',
    version: '1.1.0',
    description: 'Backend API for Gaming Social App with Redis & Socket.IO',
    features: {
      redis: redisConfig.isConnected() ? 'connected' : 'disconnected',
      socketio: 'enabled'
    },
    endpoints: {
      user: '/api/user',
      friends: '/api/friends',
      trending: '/api/trending',
      featured: '/api/featured',
      clips: '/api/clips',
      lives: '/api/lives',
      feed: '/api/feed',
      health: '/api/health'
    }
  });
});

/**
 * Socket.IO - Real-time Events
 */

// Store active users per stream
const streamViewers = new Map();

io.on('connection', (socket) => {
  console.log(`🔌 Socket connected: ${socket.id}`);

  // Join a stream room (for live chat)
  socket.on('join_stream', (streamId) => {
    socket.join(`stream:${streamId}`);
    
    // Track viewer count
    if (!streamViewers.has(streamId)) {
      streamViewers.set(streamId, new Set());
    }
    streamViewers.get(streamId).add(socket.id);
    
    // Broadcast updated viewer count
    io.to(`stream:${streamId}`).emit('viewer_count', {
      streamId,
      count: streamViewers.get(streamId).size
    });
    
    console.log(`👁️ Socket ${socket.id} joined stream ${streamId}`);
  });

  // Leave a stream room
  socket.on('leave_stream', (streamId) => {
    socket.leave(`stream:${streamId}`);
    
    if (streamViewers.has(streamId)) {
      streamViewers.get(streamId).delete(socket.id);
      io.to(`stream:${streamId}`).emit('viewer_count', {
        streamId,
        count: streamViewers.get(streamId).size
      });
    }
    
    console.log(`👋 Socket ${socket.id} left stream ${streamId}`);
  });

  // Send chat message
  socket.on('chat_message', async (data) => {
    const { streamId, userId, username, avatar, message } = data;
    
    const chatMessage = {
      id: Date.now(),
      userId,
      username,
      avatar,
      message,
      timestamp: new Date().toISOString()
    };
    
    // Broadcast to all users in the stream
    io.to(`stream:${streamId}`).emit('new_message', chatMessage);
    
    // Optionally cache recent messages in Redis
    try {
      const cacheKey = `stream:${streamId}:messages`;
      const messages = await redisConfig.get(cacheKey) || [];
      messages.push(chatMessage);
      // Keep only last 100 messages
      if (messages.length > 100) messages.shift();
      await redisConfig.set(cacheKey, messages, 3600); // 1 hour TTL
    } catch (err) {
      console.error('Failed to cache message:', err);
    }
  });

  // Handle disconnect
  socket.on('disconnect', () => {
    // Remove from all stream viewer counts
    streamViewers.forEach((viewers, streamId) => {
      if (viewers.has(socket.id)) {
        viewers.delete(socket.id);
        io.to(`stream:${streamId}`).emit('viewer_count', {
          streamId,
          count: viewers.size
        });
      }
    });
    
    console.log(`🔌 Socket disconnected: ${socket.id}`);
  });
});

// Make io accessible in routes
app.set('io', io);

/**
 * Error Handling
 */

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.path
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(500).json({
    success: false,
    error: 'Internal server error'
  });
});

/**
 * Start Server
 */

// Connect to Redis, then start server
const startServer = async () => {
  // Try to connect to Redis
  const redisConnected = await redisConfig.connect();
  
  server.listen(PORT, () => {
    console.log('='.repeat(50));
    console.log('🎮 Gaming Social API Server');
    console.log('='.repeat(50));
    console.log(`✅ Server running on http://localhost:${PORT}`);
    console.log(`🔴 Redis: ${redisConnected ? 'Connected' : 'Offline (caching disabled)'}`);
    console.log(`🔌 Socket.IO: Enabled`);
    console.log(`📚 API Documentation: http://localhost:${PORT}/`);
    console.log(`❤️  Health Check: http://localhost:${PORT}/api/health`);
    console.log('='.repeat(50));
  });
};

startServer();

module.exports = { app, io };
