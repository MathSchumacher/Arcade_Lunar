/**
 * API Routes
 * Defines all API endpoints for the Gaming Social App
 */

const express = require('express');
const router = express.Router();

// Import controllers
const { getCurrentUser } = require('../controllers/userController');
const { getFriends } = require('../controllers/friendsController');
const { getTrending, getFeaturedEvent } = require('../controllers/trendingController');
const { getClips, getClipById } = require('../controllers/clipsController');
const { getLives } = require('../controllers/livesController');
const { getFeed, getPostById } = require('../controllers/feedController');

/**
 * User Routes
 */
router.get('/user', getCurrentUser);

/**
 * Friends Routes
 */
router.get('/friends', getFriends);

/**
 * Trending Routes
 */
router.get('/trending', getTrending);
router.get('/featured', getFeaturedEvent);

/**
 * Clips Routes
 */
router.get('/clips', getClips);
router.get('/clips/:id', getClipById);

/**
 * Lives Routes
 */
router.get('/lives', getLives);

/**
 * Feed Routes
 */
router.get('/feed', getFeed);
router.get('/feed/:id', getPostById);

/**
 * Health Check
 */
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Gaming Social API is running',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
