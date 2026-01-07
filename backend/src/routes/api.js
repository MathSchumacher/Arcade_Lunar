/**
 * API Routes
 * Defines all API endpoints for the Gaming Social App
 */

const express = require('express');
const router = express.Router();

// Import middleware
const { authMiddleware, optionalAuth } = require('../middleware/auth');

// Import controllers
const { getCurrentUser } = require('../controllers/userController');
const { getFriends, addFriend, updateFriend, removeFriend } = require('../controllers/friendsController');
const { getTrending, getFeaturedEvent } = require('../controllers/trendingController');
const { getClips, getClipById, getUserClips, createClip, toggleClipLike, deleteClip } = require('../controllers/clipsController');
const { getLives, getLiveById, getFollowingLives } = require('../controllers/livesController');
const { getFeed, getPostById } = require('../controllers/feedController');
const { register, login, verify, resendCode, getMe, logout, requestEmailVerification, forgotPassword, resetPassword, socialLogin } = require('../controllers/authController');
const { searchUsers, searchPosts } = require('../controllers/searchController');
const { getProfile, followUser, unfollowUser, getFollowers, getFollowing, getUserPosts } = require('../controllers/profileController');
const { savePost, unsavePost, getSavedPosts } = require('../controllers/savedController');
const { getNotifications, markAsRead, markAllAsRead, getUnreadCount } = require('../controllers/notificationsController');
const { getMessages, sendMessage, deleteMessage } = require('../controllers/chatController');
const { 
  getFeed: getPostsFeed, getTrending: getPostsTrending, 
  toggleLike, addComment, getComments, createPost, 
  optionalAuth: postsOptionalAuth, requireAuth: postsRequireAuth 
} = require('../controllers/postsController');

/**
 * Auth Routes
 */
router.post('/auth/register', register);
router.post('/auth/login', login);
router.post('/auth/verify', verify);
router.post('/auth/resend-code', resendCode);
router.get('/auth/me', authMiddleware, getMe);
router.post('/auth/logout', authMiddleware, logout);
router.post('/auth/request-email-verification', authMiddleware, requestEmailVerification);
router.post('/auth/forgot-password', forgotPassword);
router.post('/auth/reset-password', resetPassword);
router.post('/auth/social-login', socialLogin);

/**
 * User Routes
 */
router.get('/user', getCurrentUser);

/**
 * Search Routes
 */
router.get('/search', optionalAuth, searchUsers);
router.get('/search/posts', optionalAuth, searchPosts);

/**
 * Profile Routes
 */
router.get('/users/:idOrUsername/profile', optionalAuth, getProfile);
router.post('/users/:id/follow', authMiddleware, followUser);
router.delete('/users/:id/follow', authMiddleware, unfollowUser);
router.get('/users/:id/followers', optionalAuth, getFollowers);
router.get('/users/:id/following', optionalAuth, getFollowing);
router.get('/users/:id/posts', optionalAuth, getUserPosts);

/**
 * Friends Routes
 */
router.get('/friends', optionalAuth, getFriends);
router.post('/friends/:userId', authMiddleware, addFriend);
router.put('/friends/:userId', authMiddleware, updateFriend);
router.delete('/friends/:userId', authMiddleware, removeFriend);

/**
 * Trending Routes
 */
router.get('/trending', optionalAuth, getTrending);
router.get('/featured', getFeaturedEvent);

/**
 * Clips Routes (Moments)
 */
router.get('/clips', optionalAuth, getClips);
router.get('/clips/:id', optionalAuth, getClipById);
router.get('/users/:userId/clips', optionalAuth, getUserClips);
router.post('/clips', authMiddleware, createClip);
router.post('/clips/:id/like', authMiddleware, toggleClipLike);
router.delete('/clips/:id', authMiddleware, deleteClip);

/**
 * Lives Routes
 */
router.get('/lives', optionalAuth, getLives);
router.get('/lives/following', authMiddleware, getFollowingLives);
router.get('/lives/:id', optionalAuth, getLiveById);

/**
 * Feed Routes
 */
router.get('/feed', optionalAuth, getFeed);
router.get('/feed/:id', optionalAuth, getPostById);

/**
 * Posts Routes (CRUD operations)
 */
router.get('/posts/feed', postsOptionalAuth, getPostsFeed);
router.get('/posts/trending', postsOptionalAuth, getPostsTrending);
router.post('/posts', postsRequireAuth, createPost);
router.post('/posts/:id/like', postsRequireAuth, toggleLike);
router.post('/posts/:id/comment', postsRequireAuth, addComment);
router.get('/posts/:id/comments', getComments);
router.post('/posts/:id/save', authMiddleware, savePost);
router.delete('/posts/:id/save', authMiddleware, unsavePost);

/**
 * Saved Posts Routes
 */
router.get('/saved', authMiddleware, getSavedPosts);

/**
 * Notifications Routes
 */
router.get('/notifications', authMiddleware, getNotifications);
router.get('/notifications/count', authMiddleware, getUnreadCount);
router.put('/notifications/read-all', authMiddleware, markAllAsRead);
router.put('/notifications/:id/read', authMiddleware, markAsRead);

/**
 * Chat Routes (Stream Chat)
 */
router.get('/streams/:streamId/chat', getMessages);
router.post('/streams/:streamId/chat', authMiddleware, sendMessage);
router.delete('/streams/:streamId/chat/:messageId', authMiddleware, deleteMessage);

/**
 * Health Check
 */
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Gaming Social API is running',
    timestamp: new Date().toISOString(),
    version: '2.0.0',
    features: {
      database: 'PostgreSQL',
      auth: 'JWT',
      debugMode: process.env.NODE_ENV !== 'production'
    }
  });
});

module.exports = router;
