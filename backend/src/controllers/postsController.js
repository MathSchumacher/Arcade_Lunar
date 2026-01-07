/**
 * Posts Controller
 * Handles feed, trending, likes, and comments
 */

const db = require('../config/database');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

/**
 * Middleware to extract user from token (optional auth)
 */
const optionalAuth = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (token) {
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      req.userId = decoded.userId;
    } catch (e) {
      // Invalid token, but optional so continue
    }
  }
  next();
};

/**
 * Middleware to require authentication
 */
const requireAuth = (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) {
    return res.status(401).json({ success: false, error: 'Authentication required' });
  }
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (e) {
    return res.status(401).json({ success: false, error: 'Invalid token' });
  }
};

/**
 * Get feed posts (paginated)
 * GET /api/posts/feed?page=1&limit=20
 */
const getFeed = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT 
        p.id, p.content, p.images, p.likes_count, p.comments_count, 
        p.shares_count, p.views_count, p.created_at,
        u.id as author_id, u.username, u.avatar_url, u.is_verified,
        CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as is_liked
      FROM posts p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = $1
      WHERE p.is_deleted = false
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3`,
      [req.userId || 0, limit, offset]
    );

    const posts = result.rows.map(row => ({
      id: row.id,
      content: row.content,
      images: row.images || [],
      likes: row.likes_count,
      comments: row.comments_count,
      shares: row.shares_count,
      views: row.views_count,
      createdAt: row.created_at,
      isLiked: row.is_liked,
      author: {
        id: row.author_id,
        username: row.username,
        avatar: row.avatar_url,
        isVerified: row.is_verified
      }
    }));

    res.json({
      success: true,
      data: { posts, page, limit, hasMore: posts.length === limit }
    });
  } catch (error) {
    console.error('getFeed error:', error);
    res.status(500).json({ success: false, error: 'Failed to get feed' });
  }
};

/**
 * Get trending posts (by engagement score)
 * GET /api/posts/trending?limit=20
 */
const getTrending = async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);

    // Trending algorithm: (likes + comments*2.5 + shares*3 + views*0.1) * recency_bonus
    const result = await db.query(
      `SELECT 
        p.id, p.content, p.images, p.likes_count, p.comments_count, 
        p.shares_count, p.views_count, p.created_at,
        u.id as author_id, u.username, u.avatar_url, u.is_verified,
        CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as is_liked,
        (p.likes_count + p.comments_count * 2.5 + p.shares_count * 3 + p.views_count * 0.1) * 
          CASE 
            WHEN p.created_at > NOW() - INTERVAL '6 hours' THEN 2.0
            WHEN p.created_at > NOW() - INTERVAL '24 hours' THEN 1.5
            ELSE 1.0
          END as engagement_score
      FROM posts p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = $1
      WHERE p.is_deleted = false AND p.created_at > NOW() - INTERVAL '7 days'
      ORDER BY engagement_score DESC
      LIMIT $2`,
      [req.userId || 0, limit]
    );

    const posts = result.rows.map(row => ({
      id: row.id,
      content: row.content,
      images: row.images || [],
      likes: row.likes_count,
      comments: row.comments_count,
      shares: row.shares_count,
      views: row.views_count,
      createdAt: row.created_at,
      isLiked: row.is_liked,
      engagementScore: Math.round(row.engagement_score),
      author: {
        id: row.author_id,
        username: row.username,
        avatar: row.avatar_url,
        isVerified: row.is_verified
      }
    }));

    res.json({ success: true, data: { posts } });
  } catch (error) {
    console.error('getTrending error:', error);
    res.status(500).json({ success: false, error: 'Failed to get trending' });
  }
};

/**
 * Toggle like on a post
 * POST /api/posts/:id/like
 */
const toggleLike = async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.userId;

    // Check if already liked
    const existing = await db.query(
      'SELECT id FROM post_likes WHERE post_id = $1 AND user_id = $2',
      [postId, userId]
    );

    let isLiked;
    if (existing.rows.length > 0) {
      // Unlike
      await db.query('DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2', [postId, userId]);
      await db.query('UPDATE posts SET likes_count = likes_count - 1 WHERE id = $1', [postId]);
      isLiked = false;
    } else {
      // Like
      await db.query('INSERT INTO post_likes (post_id, user_id) VALUES ($1, $2)', [postId, userId]);
      await db.query('UPDATE posts SET likes_count = likes_count + 1 WHERE id = $1', [postId]);
      isLiked = true;
    }

    // Get updated count
    const countResult = await db.query('SELECT likes_count FROM posts WHERE id = $1', [postId]);

    res.json({
      success: true,
      data: {
        postId,
        isLiked,
        likesCount: countResult.rows[0]?.likes_count || 0
      }
    });
  } catch (error) {
    console.error('toggleLike error:', error);
    res.status(500).json({ success: false, error: 'Failed to toggle like' });
  }
};

/**
 * Add comment to a post
 * POST /api/posts/:id/comment
 */
const addComment = async (req, res) => {
  try {
    const postId = req.params.id;
    const userId = req.userId;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Comment content required' });
    }

    // Insert comment
    const result = await db.query(
      `INSERT INTO post_comments (post_id, user_id, content)
       VALUES ($1, $2, $3)
       RETURNING id, content, created_at`,
      [postId, userId, content.trim()]
    );

    // Update comment count
    await db.query('UPDATE posts SET comments_count = comments_count + 1 WHERE id = $1', [postId]);

    // Get user info
    const userResult = await db.query('SELECT username, avatar_url FROM users WHERE id = $1', [userId]);

    res.status(201).json({
      success: true,
      data: {
        id: result.rows[0].id,
        content: result.rows[0].content,
        createdAt: result.rows[0].created_at,
        author: {
          id: userId,
          username: userResult.rows[0]?.username,
          avatar: userResult.rows[0]?.avatar_url
        }
      }
    });
  } catch (error) {
    console.error('addComment error:', error);
    res.status(500).json({ success: false, error: 'Failed to add comment' });
  }
};

/**
 * Get comments for a post
 * GET /api/posts/:id/comments?page=1&limit=20
 */
const getComments = async (req, res) => {
  try {
    const postId = req.params.id;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT c.id, c.content, c.created_at,
              u.id as author_id, u.username, u.avatar_url
       FROM post_comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.post_id = $1
       ORDER BY c.created_at DESC
       LIMIT $2 OFFSET $3`,
      [postId, limit, offset]
    );

    const comments = result.rows.map(row => ({
      id: row.id,
      content: row.content,
      createdAt: row.created_at,
      author: {
        id: row.author_id,
        username: row.username,
        avatar: row.avatar_url
      }
    }));

    res.json({
      success: true,
      data: { comments, page, limit, hasMore: comments.length === limit }
    });
  } catch (error) {
    console.error('getComments error:', error);
    res.status(500).json({ success: false, error: 'Failed to get comments' });
  }
};

/**
 * Create a new post
 * POST /api/posts
 */
const createPost = async (req, res) => {
  try {
    const userId = req.userId;
    const { content, images } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Post content required' });
    }

    const result = await db.query(
      `INSERT INTO posts (user_id, content, images)
       VALUES ($1, $2, $3)
       RETURNING id, content, images, likes_count, comments_count, shares_count, created_at`,
      [userId, content.trim(), images || []]
    );

    // Get user info
    const userResult = await db.query('SELECT username, avatar_url, is_verified FROM users WHERE id = $1', [userId]);

    res.status(201).json({
      success: true,
      data: {
        id: result.rows[0].id,
        content: result.rows[0].content,
        images: result.rows[0].images,
        likes: result.rows[0].likes_count,
        comments: result.rows[0].comments_count,
        shares: result.rows[0].shares_count,
        createdAt: result.rows[0].created_at,
        isLiked: false,
        author: {
          id: userId,
          username: userResult.rows[0]?.username,
          avatar: userResult.rows[0]?.avatar_url,
          isVerified: userResult.rows[0]?.is_verified
        }
      }
    });
  } catch (error) {
    console.error('createPost error:', error);
    res.status(500).json({ success: false, error: 'Failed to create post' });
  }
};

module.exports = {
  getFeed,
  getTrending,
  toggleLike,
  addComment,
  getComments,
  createPost,
  optionalAuth,
  requireAuth
};
