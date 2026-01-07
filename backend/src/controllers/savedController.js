/**
 * Saved Posts Controller
 * Handles bookmarking/saving posts functionality
 */

const db = require('../config/database');

/**
 * Save a post
 * @route POST /api/posts/:id/save
 */
const savePost = async (req, res) => {
  try {
    const userId = req.user?.id;
    const postId = parseInt(req.params.id);

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    // Check if already saved
    const existing = await db.query(
      'SELECT id FROM saved_posts WHERE user_id = $1 AND post_id = $2',
      [userId, postId]
    );

    if (existing.rows.length > 0) {
      return res.status(400).json({ success: false, error: 'Post already saved' });
    }

    // Save post
    await db.query(
      'INSERT INTO saved_posts (user_id, post_id) VALUES ($1, $2)',
      [userId, postId]
    );

    res.json({
      success: true,
      message: 'Post saved',
      data: { isSaved: true }
    });
  } catch (error) {
    console.error('savePost error:', error);
    res.status(500).json({ success: false, error: 'Failed to save post' });
  }
};

/**
 * Unsave a post
 * @route DELETE /api/posts/:id/save
 */
const unsavePost = async (req, res) => {
  try {
    const userId = req.user?.id;
    const postId = parseInt(req.params.id);

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    await db.query(
      'DELETE FROM saved_posts WHERE user_id = $1 AND post_id = $2',
      [userId, postId]
    );

    res.json({
      success: true,
      message: 'Post unsaved',
      data: { isSaved: false }
    });
  } catch (error) {
    console.error('unsavePost error:', error);
    res.status(500).json({ success: false, error: 'Failed to unsave post' });
  }
};

/**
 * Get saved posts
 * @route GET /api/saved
 */
const getSavedPosts = async (req, res) => {
  try {
    const userId = req.user?.id;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;
    const searchQuery = req.query.q;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    let query = `
      SELECT 
        p.id, p.content, p.images, p.likes_count, p.comments_count,
        p.shares_count, p.created_at,
        u.id as author_id, u.username, u.avatar_url, u.is_verified,
        up.display_name,
        CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as is_liked,
        sp.created_at as saved_at
      FROM saved_posts sp
      JOIN posts p ON sp.post_id = p.id
      JOIN users u ON p.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = $1
      WHERE sp.user_id = $1 AND p.is_deleted = false
    `;

    const params = [userId];

    if (searchQuery && searchQuery.trim().length >= 2) {
      query += ` AND LOWER(p.content) LIKE $${params.length + 1}`;
      params.push(`%${searchQuery.trim().toLowerCase()}%`);
    }

    query += ` ORDER BY sp.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    const posts = result.rows.map(row => ({
      id: row.id,
      content: row.content,
      images: row.images || [],
      likes: row.likes_count,
      comments: row.comments_count,
      shares: row.shares_count,
      createdAt: row.created_at,
      savedAt: row.saved_at,
      isLiked: row.is_liked,
      isSaved: true,
      author: {
        id: row.author_id,
        username: row.username,
        displayName: row.display_name || row.username,
        avatar: row.avatar_url,
        isVerified: row.is_verified
      }
    }));

    res.json({
      success: true,
      data: posts,
      meta: {
        page,
        limit,
        hasMore: posts.length === limit,
        searchQuery: searchQuery || null
      }
    });
  } catch (error) {
    console.error('getSavedPosts error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch saved posts' });
  }
};

module.exports = {
  savePost,
  unsavePost,
  getSavedPosts
};
