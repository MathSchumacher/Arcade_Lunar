/**
 * Posts Routes
 * Handles all /api/posts endpoints
 */

const express = require('express');
const router = express.Router();
const {
  getFeed,
  getTrending,
  toggleLike,
  addComment,
  getComments,
  createPost,
  optionalAuth,
  requireAuth
} = require('../controllers/postsController');

// Public routes (with optional auth for personalization)
router.get('/feed', optionalAuth, getFeed);
router.get('/trending', optionalAuth, getTrending);
router.get('/:id/comments', getComments);

// Protected routes (require authentication)
router.post('/', requireAuth, createPost);
router.post('/:id/like', requireAuth, toggleLike);
router.post('/:id/comment', requireAuth, addComment);

module.exports = router;
