/**
 * Search Controller
 * Handles user and content search with database and optional Redis caching
 */

const db = require('../config/database');

const isDebugMode = process.env.NODE_ENV !== 'production';

/**
 * Search users
 * @route GET /api/search?q=query&contactsOnly=true|false
 */
const searchUsers = async (req, res) => {
  try {
    const { q, contactsOnly } = req.query;
    const userId = req.user?.id;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);

    if (!q || q.trim().length < 2) {
      return res.status(400).json({
        success: false,
        error: 'Search query must be at least 2 characters'
      });
    }

    const searchTerm = `%${q.trim().toLowerCase()}%`;
    let query;
    let params;

    if (contactsOnly === 'true' && userId) {
      // Search only in followed users
      query = `
        SELECT DISTINCT
          u.id, u.username, u.avatar_url, u.is_verified,
          up.display_name, up.bio,
          true as is_followed,
          CASE WHEN ls.is_live = true THEN true ELSE false END as is_streaming,
          ls.title as stream_title,
          gc.name as stream_game
        FROM users u
        JOIN follows f ON u.id = f.following_id AND f.follower_id = $1
        LEFT JOIN user_profiles up ON u.id = up.user_id
        LEFT JOIN live_streams ls ON u.id = ls.user_id AND ls.is_live = true
        LEFT JOIN game_categories gc ON ls.category_id = gc.id
        WHERE (LOWER(u.username) LIKE $2 OR LOWER(up.display_name) LIKE $2)
          AND u.is_verified = true
        ORDER BY ls.is_live DESC NULLS LAST, u.username ASC
        LIMIT $3
      `;
      params = [userId, searchTerm, limit];
    } else {
      // Search globally
      query = `
        SELECT DISTINCT
          u.id, u.username, u.avatar_url, u.is_verified,
          up.display_name, up.bio,
          CASE WHEN f.follower_id IS NOT NULL THEN true ELSE false END as is_followed,
          CASE WHEN ls.is_live = true THEN true ELSE false END as is_streaming,
          ls.title as stream_title,
          gc.name as stream_game,
          (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count
        FROM users u
        LEFT JOIN user_profiles up ON u.id = up.user_id
        LEFT JOIN follows f ON u.id = f.following_id AND f.follower_id = $1
        LEFT JOIN live_streams ls ON u.id = ls.user_id AND ls.is_live = true
        LEFT JOIN game_categories gc ON ls.category_id = gc.id
        WHERE (LOWER(u.username) LIKE $2 OR LOWER(up.display_name) LIKE $2)
          AND u.is_verified = true
        ORDER BY followers_count DESC, ls.is_live DESC NULLS LAST, u.username ASC
        LIMIT $3
      `;
      params = [userId || 0, searchTerm, limit];
    }

    const result = await db.query(query, params);

    const users = result.rows.map(row => ({
      id: row.id,
      username: row.username,
      displayName: row.display_name || row.username,
      avatar: row.avatar_url,
      bio: row.bio,
      isVerified: row.is_verified,
      isFollowed: row.is_followed,
      isStreaming: row.is_streaming,
      streamTitle: row.stream_title,
      streamGame: row.stream_game,
      followersCount: row.followers_count
    }));

    res.json({
      success: true,
      data: users,
      meta: {
        query: q,
        contactsOnly: contactsOnly === 'true',
        total: users.length
      }
    });
  } catch (error) {
    console.error('searchUsers error:', error);
    res.status(500).json({
      success: false,
      error: 'Search failed'
    });
  }
};

/**
 * Search posts
 * @route GET /api/search/posts?q=query
 */
const searchPosts = async (req, res) => {
  try {
    const { q } = req.query;
    const userId = req.user?.id;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);

    if (!q || q.trim().length < 2) {
      return res.status(400).json({
        success: false,
        error: 'Search query must be at least 2 characters'
      });
    }

    const searchTerm = `%${q.trim().toLowerCase()}%`;

    const result = await db.query(
      `SELECT 
        p.id, p.content, p.images, p.likes_count, p.comments_count, p.created_at,
        u.id as author_id, u.username, u.avatar_url, u.is_verified,
        up.display_name,
        CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as is_liked
      FROM posts p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = $1
      WHERE LOWER(p.content) LIKE $2 AND p.is_deleted = false
      ORDER BY p.likes_count DESC, p.created_at DESC
      LIMIT $3`,
      [userId || 0, searchTerm, limit]
    );

    const posts = result.rows.map(row => ({
      id: row.id,
      content: row.content,
      images: row.images || [],
      likes: row.likes_count,
      comments: row.comments_count,
      createdAt: row.created_at,
      isLiked: row.is_liked,
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
        query: q,
        total: posts.length
      }
    });
  } catch (error) {
    console.error('searchPosts error:', error);
    res.status(500).json({
      success: false,
      error: 'Search failed'
    });
  }
};

module.exports = {
  searchUsers,
  searchPosts
};
