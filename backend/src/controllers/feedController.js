/**
 * Feed Controller
 * Handles social feed API requests
 * Uses PostgreSQL database with Redis caching and mock data fallback for debug mode
 */

const db = require('../config/database');
const redis = require('../config/redis');
const { feed: mockFeed } = require('../data/mockData');

// Check if we're in debug mode
const isDebugMode = process.env.NODE_ENV !== 'production';

// Cache TTL: 2 minutes for feed
const FEED_CACHE_TTL = 120;

/**
 * Get social feed posts
 * @route GET /api/feed
 */
const getFeed = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;
    const userId = req.user?.id || 0;

    // Try database first
    const result = await db.query(
      `SELECT 
        p.id, p.content, p.images, p.video_url, p.video_type, p.video_thumbnail,
        p.likes_count, p.comments_count, p.shares_count, p.views_count, 
        p.created_at, p.is_mock,
        u.id as author_id, u.username, u.avatar_url, u.is_verified,
        up.display_name,
        CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as is_liked,
        CASE WHEN sp.user_id IS NOT NULL THEN true ELSE false END as is_saved
      FROM posts p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = $1
      LEFT JOIN saved_posts sp ON p.id = sp.post_id AND sp.user_id = $1
      WHERE p.is_deleted = false
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    // If no posts in database and debug mode, merge with mock data
    if (result.rows.length === 0 && isDebugMode) {
      console.log('📦 No posts in DB, returning mock data (debug mode)');
      const sortedFeed = [...mockFeed].sort((a, b) => 
        new Date(b.createdAt) - new Date(a.createdAt)
      );

      return res.json({
        success: true,
        data: sortedFeed,
        meta: {
          total: mockFeed.length,
          page,
          limit,
          hasMore: false,
          source: 'mock'
        }
      });
    }

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
      isSaved: row.is_saved,
      isMock: row.is_mock,
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
        total: posts.length,
        page,
        limit,
        hasMore: posts.length === limit,
        source: 'database'
      }
    });
  } catch (error) {
    console.error('getFeed error:', error);
    
    // Fallback to mock data on database error (debug mode only)
    if (isDebugMode) {
      console.log('⚠️ Database error, falling back to mock data');
      const sortedFeed = [...mockFeed].sort((a, b) => 
        new Date(b.createdAt) - new Date(a.createdAt)
      );
      
      return res.json({
        success: true,
        data: sortedFeed,
        meta: {
          total: mockFeed.length,
          hasMore: false,
          source: 'mock_fallback'
        }
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch feed data'
    });
  }
};

/**
 * Get single post by ID
 * @route GET /api/feed/:id
 */
const getPostById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id || 0;

    const result = await db.query(
      `SELECT 
        p.id, p.content, p.images, p.likes_count, p.comments_count, 
        p.shares_count, p.views_count, p.created_at,
        u.id as author_id, u.username, u.avatar_url, u.is_verified,
        up.display_name,
        CASE WHEN pl.user_id IS NOT NULL THEN true ELSE false END as is_liked,
        CASE WHEN sp.user_id IS NOT NULL THEN true ELSE false END as is_saved
      FROM posts p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN post_likes pl ON p.id = pl.post_id AND pl.user_id = $2
      LEFT JOIN saved_posts sp ON p.id = sp.post_id AND sp.user_id = $2
      WHERE p.id = $1 AND p.is_deleted = false`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      // Try mock data in debug mode
      if (isDebugMode) {
        const post = mockFeed.find(p => p.id === id);
        if (post) {
          return res.json({ success: true, data: post, source: 'mock' });
        }
      }
      
      return res.status(404).json({
        success: false,
        error: 'Post not found'
      });
    }

    const row = result.rows[0];
    res.json({
      success: true,
      data: {
        id: row.id,
        content: row.content,
        images: row.images || [],
        likes: row.likes_count,
        comments: row.comments_count,
        shares: row.shares_count,
        views: row.views_count,
        createdAt: row.created_at,
        isLiked: row.is_liked,
        isSaved: row.is_saved,
        author: {
          id: row.author_id,
          username: row.username,
          displayName: row.display_name || row.username,
          avatar: row.avatar_url,
          isVerified: row.is_verified
        }
      }
    });
  } catch (error) {
    console.error('getPostById error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch post'
    });
  }
};

/**
 * Create a new post (with video embed support)
 * @route POST /api/feed
 */
const createPost = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const { content, images, videoUrl } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Content is required' });
    }

    // Parse video URL if provided or extract from content
    let videoType = null;
    let videoThumbnail = null;
    let finalVideoUrl = videoUrl || null;

    // Try to import video parser
    try {
      const { processPostVideo } = require('../utils/videoParser');
      const videoInfo = processPostVideo(content, videoUrl);
      finalVideoUrl = videoInfo.videoUrl;
      videoType = videoInfo.videoType;
      videoThumbnail = videoInfo.videoThumbnail;
    } catch (e) {
      console.log('Video parser not available:', e.message);
    }

    const result = await db.query(
      `INSERT INTO posts (user_id, content, images, video_url, video_type, video_thumbnail)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, content, images, video_url, video_type, video_thumbnail, created_at`,
      [userId, content.trim(), images || [], finalVideoUrl, videoType, videoThumbnail]
    );

    const post = result.rows[0];

    // Get author info
    const authorResult = await db.query(
      `SELECT u.username, u.avatar_url, u.is_verified, up.display_name
       FROM users u LEFT JOIN user_profiles up ON u.id = up.user_id
       WHERE u.id = $1`,
      [userId]
    );
    const author = authorResult.rows[0];

    res.status(201).json({
      success: true,
      message: 'Post created successfully',
      data: {
        id: post.id,
        content: post.content,
        images: post.images,
        videoUrl: post.video_url,
        videoType: post.video_type,
        videoThumbnail: post.video_thumbnail,
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
        createdAt: post.created_at,
        isLiked: false,
        isSaved: false,
        author: {
          id: userId,
          username: author?.username,
          displayName: author?.display_name || author?.username,
          avatar: author?.avatar_url,
          isVerified: author?.is_verified
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
  getPostById,
  createPost
};
