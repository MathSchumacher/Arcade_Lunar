/**
 * Profile Controller
 * Handles user profile viewing, following, and stats
 */

const db = require('../config/database');

/**
 * Get user profile by ID or username
 * @route GET /api/users/:idOrUsername/profile
 */
const getProfile = async (req, res) => {
  try {
    const { idOrUsername } = req.params;
    const currentUserId = req.user?.id;

    // Check if it's an ID (number) or username
    const isId = !isNaN(parseInt(idOrUsername));
    
    const result = await db.query(
      `SELECT 
        u.id, u.username, u.avatar_url, u.is_verified, u.created_at,
        up.display_name, up.bio, up.banner_url, up.social_links,
        (SELECT COUNT(*) FROM follows WHERE following_id = u.id) as followers_count,
        (SELECT COUNT(*) FROM follows WHERE follower_id = u.id) as following_count,
        (SELECT COUNT(*) FROM posts WHERE user_id = u.id AND is_deleted = false) as posts_count,
        CASE WHEN f.follower_id IS NOT NULL THEN true ELSE false END as is_followed,
        CASE WHEN ls.is_live = true THEN true ELSE false END as is_streaming,
        ls.id as stream_id, ls.title as stream_title,
        gc.name as stream_game
      FROM users u
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN follows f ON u.id = f.following_id AND f.follower_id = $2
      LEFT JOIN live_streams ls ON u.id = ls.user_id AND ls.is_live = true
      LEFT JOIN game_categories gc ON ls.category_id = gc.id
      WHERE ${isId ? 'u.id = $1' : 'LOWER(u.username) = LOWER($1)'}`,
      [idOrUsername, currentUserId || 0]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const row = result.rows[0];
    res.json({
      success: true,
      data: {
        id: row.id,
        username: row.username,
        displayName: row.display_name || row.username,
        avatar: row.avatar_url,
        banner: row.banner_url,
        bio: row.bio,
        isVerified: row.is_verified,
        isFollowed: row.is_followed,
        isStreaming: row.is_streaming,
        streamId: row.stream_id,
        streamTitle: row.stream_title,
        streamGame: row.stream_game,
        socialLinks: row.social_links || {},
        stats: {
          followers: row.followers_count,
          following: row.following_count,
          posts: row.posts_count
        },
        joinedAt: row.created_at
      }
    });
  } catch (error) {
    console.error('getProfile error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch profile'
    });
  }
};

/**
 * Follow a user
 * @route POST /api/users/:id/follow
 */
const followUser = async (req, res) => {
  try {
    const currentUserId = req.user?.id;
    const targetUserId = parseInt(req.params.id);

    if (!currentUserId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    if (currentUserId === targetUserId) {
      return res.status(400).json({ success: false, error: 'Cannot follow yourself' });
    }

    // Check if already following
    const existing = await db.query(
      'SELECT id FROM follows WHERE follower_id = $1 AND following_id = $2',
      [currentUserId, targetUserId]
    );

    if (existing.rows.length > 0) {
      return res.status(400).json({ success: false, error: 'Already following this user' });
    }

    // Create follow
    await db.query(
      'INSERT INTO follows (follower_id, following_id) VALUES ($1, $2)',
      [currentUserId, targetUserId]
    );

    // Create notification for the followed user
    await db.query(
      `INSERT INTO notifications (user_id, type, from_user_id, message)
       VALUES ($1, 'follow', $2, 'started following you')`,
      [targetUserId, currentUserId]
    );

    // Get updated follower count
    const countResult = await db.query(
      'SELECT COUNT(*) as count FROM follows WHERE following_id = $1',
      [targetUserId]
    );

    res.json({
      success: true,
      message: 'Now following user',
      data: {
        isFollowed: true,
        followersCount: parseInt(countResult.rows[0].count)
      }
    });
  } catch (error) {
    console.error('followUser error:', error);
    res.status(500).json({ success: false, error: 'Failed to follow user' });
  }
};

/**
 * Unfollow a user
 * @route DELETE /api/users/:id/follow
 */
const unfollowUser = async (req, res) => {
  try {
    const currentUserId = req.user?.id;
    const targetUserId = parseInt(req.params.id);

    if (!currentUserId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    await db.query(
      'DELETE FROM follows WHERE follower_id = $1 AND following_id = $2',
      [currentUserId, targetUserId]
    );

    // Get updated follower count
    const countResult = await db.query(
      'SELECT COUNT(*) as count FROM follows WHERE following_id = $1',
      [targetUserId]
    );

    res.json({
      success: true,
      message: 'Unfollowed user',
      data: {
        isFollowed: false,
        followersCount: parseInt(countResult.rows[0].count)
      }
    });
  } catch (error) {
    console.error('unfollowUser error:', error);
    res.status(500).json({ success: false, error: 'Failed to unfollow user' });
  }
};

/**
 * Get user's followers
 * @route GET /api/users/:id/followers
 */
const getFollowers = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user?.id;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT 
        u.id, u.username, u.avatar_url, u.is_verified,
        up.display_name, up.bio,
        CASE WHEN f2.follower_id IS NOT NULL THEN true ELSE false END as is_followed
      FROM follows f
      JOIN users u ON f.follower_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN follows f2 ON u.id = f2.following_id AND f2.follower_id = $2
      WHERE f.following_id = $1
      ORDER BY f.created_at DESC
      LIMIT $3 OFFSET $4`,
      [id, currentUserId || 0, limit, offset]
    );

    const followers = result.rows.map(row => ({
      id: row.id,
      username: row.username,
      displayName: row.display_name || row.username,
      avatar: row.avatar_url,
      bio: row.bio,
      isVerified: row.is_verified,
      isFollowed: row.is_followed
    }));

    res.json({
      success: true,
      data: followers,
      meta: { page, limit, hasMore: followers.length === limit }
    });
  } catch (error) {
    console.error('getFollowers error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch followers' });
  }
};

/**
 * Get user's following
 * @route GET /api/users/:id/following
 */
const getFollowing = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user?.id;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT 
        u.id, u.username, u.avatar_url, u.is_verified,
        up.display_name, up.bio,
        CASE WHEN f2.follower_id IS NOT NULL THEN true ELSE false END as is_followed
      FROM follows f
      JOIN users u ON f.following_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN follows f2 ON u.id = f2.following_id AND f2.follower_id = $2
      WHERE f.follower_id = $1
      ORDER BY f.created_at DESC
      LIMIT $3 OFFSET $4`,
      [id, currentUserId || 0, limit, offset]
    );

    const following = result.rows.map(row => ({
      id: row.id,
      username: row.username,
      displayName: row.display_name || row.username,
      avatar: row.avatar_url,
      bio: row.bio,
      isVerified: row.is_verified,
      isFollowed: row.is_followed
    }));

    res.json({
      success: true,
      data: following,
      meta: { page, limit, hasMore: following.length === limit }
    });
  } catch (error) {
    console.error('getFollowing error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch following' });
  }
};

/**
 * Get user's posts
 * @route GET /api/users/:id/posts
 */
const getUserPosts = async (req, res) => {
  try {
    const { id } = req.params;
    const currentUserId = req.user?.id;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT 
        p.id, p.content, p.images, p.likes_count, p.comments_count,
        p.shares_count, p.created_at,
        u.id as author_id, u.username, u.avatar_url, u.is_verified,
        up.display_name,
        CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as is_liked
      FROM posts p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = $2
      WHERE p.user_id = $1 AND p.is_deleted = false
      ORDER BY p.created_at DESC
      LIMIT $3 OFFSET $4`,
      [id, currentUserId || 0, limit, offset]
    );

    const posts = result.rows.map(row => ({
      id: row.id,
      content: row.content,
      images: row.images || [],
      likes: row.likes_count,
      comments: row.comments_count,
      shares: row.shares_count,
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
      meta: { page, limit, hasMore: posts.length === limit }
    });
  } catch (error) {
    console.error('getUserPosts error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch posts' });
  }
};

module.exports = {
  getProfile,
  followUser,
  unfollowUser,
  getFollowers,
  getFollowing,
  getUserPosts
};
