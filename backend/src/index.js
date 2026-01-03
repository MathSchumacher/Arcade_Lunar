/**
 * Gaming Social App - API Server
 * Main entry point for the Express server
 */

const express = require('express');
const cors = require('cors');
const apiRoutes = require('./routes/api');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

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
 * Routes
 */

// API routes
app.use('/api', apiRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'Gaming Social API',
    version: '1.0.0',
    description: 'Backend API for Gaming Social App',
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
app.listen(PORT, () => {
  console.log('='.repeat(50));
  console.log('🎮 Gaming Social API Server');
  console.log('='.repeat(50));
  console.log(`✅ Server running on http://localhost:${PORT}`);
  console.log(`📚 API Documentation: http://localhost:${PORT}/`);
  console.log(`❤️  Health Check: http://localhost:${PORT}/api/health`);
  console.log('='.repeat(50));
});

module.exports = app;
