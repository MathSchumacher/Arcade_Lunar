/**
 * Auth Middleware
 * JWT token validation for protected routes
 */

const jwt = require('jsonwebtoken');
const db = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'arcade-lunar-secret-2026';

/**
 * Verify JWT token and attach user to request
 */
const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        error: 'Authorization token required'
      });
    }

    const token = authHeader.replace('Bearer ', '');

    // Verify JWT
    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      return res.status(401).json({
        success: false,
        error: 'Invalid or expired token'
      });
    }

    // Check if session exists and is valid
    const sessionResult = await db.query(
      'SELECT id FROM sessions WHERE token = $1 AND expires_at > NOW()',
      [token]
    );

    if (sessionResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Session expired or invalid'
      });
    }

    // Get user
    const userResult = await db.query(
      `SELECT id, email, phone, username, avatar_url, is_verified
       FROM users WHERE id = $1`,
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'User not found'
      });
    }

    // Attach user to request
    req.user = {
      id: userResult.rows[0].id,
      email: userResult.rows[0].email,
      phone: userResult.rows[0].phone,
      username: userResult.rows[0].username,
      avatarUrl: userResult.rows[0].avatar_url,
      isVerified: userResult.rows[0].is_verified
    };
    req.token = token;

    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({
      success: false,
      error: 'Authentication failed'
    });
  }
};

/**
 * Optional auth - doesn't fail if no token, but attaches user if valid
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.replace('Bearer ', '');

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      
      const userResult = await db.query(
        `SELECT id, email, phone, username, avatar_url, is_verified
         FROM users WHERE id = $1`,
        [decoded.userId]
      );

      if (userResult.rows.length > 0) {
        req.user = userResult.rows[0];
        req.token = token;
      }
    } catch (err) {
      // Token invalid, continue without user
    }

    next();
  } catch (error) {
    next();
  }
};

module.exports = {
  authMiddleware,
  optionalAuth
};
