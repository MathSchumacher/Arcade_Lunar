/**
 * Clips Controller (Moments)
 * Handles live stream clips/moments API requests
 * Uses PostgreSQL with Redis caching and mock data fallback
 */

const db = require('../config/database');
const redis = require('../config/redis');
const { quickClips } = require('../data/mockData');

const isDebugMode = process.env.NODE_ENV !== 'production';
const CLIPS_CACHE_TTL = 300; // 5 minutes

/**
 * Get all clips (trending/recent)
 * @route GET /api/clips
 */
const getClips = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;
    const sort = req.query.sort || 'recent'; // recent, popular, views
    const gameId = req.query.game;

    let orderBy = 'c.created_at DESC';
    if (sort === 'popular') orderBy = 'c.likes_count DESC';
    if (sort === 'views') orderBy = 'c.views_count DESC';

    let whereClause = 'WHERE c.is_public = true';
    let params = [limit, offset];
    
    if (gameId) {
      whereClause += ` AND c.game_id = $3`;
      params.push(gameId);
    }

    const result = await db.query(
      `SELECT 
        c.id, c.title, c.description, c.video_url, c.thumbnail_url,
        c.duration, c.views_count, c.likes_count, c.created_at,
        u.id as creator_id, u.username as creator_username, u.avatar_url as creator_avatar,
        gc.name as game_name, gc.icon_url as game_icon,
        ls.title as stream_title
      FROM clips c
      JOIN users u ON c.user_id = u.id
      LEFT JOIN game_categories gc ON c.game_id = gc.id
      LEFT JOIN live_streams ls ON c.stream_id = ls.id
      ${whereClause}
      ORDER BY ${orderBy}
      LIMIT $1 OFFSET $2`,
      params
    );

    // Fallback to mock data in debug mode
    if (result.rows.length === 0 && isDebugMode) {
      console.log('📦 No clips in DB, returning mock data');
      return res.json({
        success: true,
        data: quickClips.map(clip => ({
          ...clip,
          creator: {
            id: clip.channelId,
            username: clip.channelName,
            avatar: clip.avatar
          }
        })),
        meta: { total: quickClips.length, page, limit, source: 'mock' }
      });
    }

    const clips = result.rows.map(row => ({
      id: row.id,
      title: row.title,
      description: row.description,
      videoUrl: row.video_url,
      thumbnail: row.thumbnail_url,
      duration: row.duration,
      views: row.views_count,
      likes: row.likes_count,
      createdAt: row.created_at,
      creator: {
        id: row.creator_id,
        username: row.creator_username,
        avatar: row.creator_avatar
      },
      game: row.game_name ? { name: row.game_name, icon: row.game_icon } : null,
      streamTitle: row.stream_title
    }));

    res.json({
      success: true,
      data: clips,
      meta: { total: clips.length, page, limit, hasMore: clips.length === limit }
    });

  } catch (error) {
    console.error('Get clips error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch clips' });
  }
};

/**
 * Get clips by user (for profile Moments tab)
 * @route GET /api/clips/user/:userId
 */
const getUserClips = async (req, res) => {
  try {
    const { userId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT 
        c.id, c.title, c.video_url, c.thumbnail_url, c.duration,
        c.views_count, c.likes_count, c.created_at,
        gc.name as game_name
      FROM clips c
      LEFT JOIN game_categories gc ON c.game_id = gc.id
      WHERE c.user_id = $1 AND c.is_public = true
      ORDER BY c.created_at DESC
      LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const clips = result.rows.map(row => ({
      id: row.id,
      title: row.title,
      videoUrl: row.video_url,
      thumbnail: row.thumbnail_url,
      duration: row.duration,
      views: row.views_count,
      likes: row.likes_count,
      game: row.game_name,
      createdAt: row.created_at
    }));

    res.json({
      success: true,
      data: clips,
      meta: { total: clips.length, page, limit }
    });

  } catch (error) {
    console.error('Get user clips error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch user clips' });
  }
};

/**
 * Get single clip by ID
 * @route GET /api/clips/:id
 */
const getClipById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    const result = await db.query(
      `SELECT 
        c.id, c.title, c.description, c.video_url, c.thumbnail_url,
        c.duration, c.start_timestamp, c.end_timestamp,
        c.views_count, c.likes_count, c.created_at,
        u.id as creator_id, u.username as creator_username, u.avatar_url as creator_avatar,
        gc.name as game_name, gc.icon_url as game_icon,
        ls.title as stream_title,
        CASE WHEN cl.user_id IS NOT NULL THEN true ELSE false END as is_liked
      FROM clips c
      JOIN users u ON c.user_id = u.id
      LEFT JOIN game_categories gc ON c.game_id = gc.id
      LEFT JOIN live_streams ls ON c.stream_id = ls.id
      LEFT JOIN clip_likes cl ON c.id = cl.clip_id AND cl.user_id = $2
      WHERE c.id = $1`,
      [id, userId || 0]
    );

    if (result.rows.length === 0) {
      // Try mock data
      if (isDebugMode) {
        const mockClip = quickClips.find(c => c.id === id);
        if (mockClip) {
          return res.json({ success: true, data: mockClip, source: 'mock' });
        }
      }
      return res.status(404).json({ success: false, error: 'Clip not found' });
    }

    const row = result.rows[0];

    // Increment view count
    await db.query('UPDATE clips SET views_count = views_count + 1 WHERE id = $1', [id]);

    res.json({
      success: true,
      data: {
        id: row.id,
        title: row.title,
        description: row.description,
        videoUrl: row.video_url,
        thumbnail: row.thumbnail_url,
        duration: row.duration,
        startTimestamp: row.start_timestamp,
        endTimestamp: row.end_timestamp,
        views: row.views_count + 1,
        likes: row.likes_count,
        isLiked: row.is_liked,
        createdAt: row.created_at,
        creator: {
          id: row.creator_id,
          username: row.creator_username,
          avatar: row.creator_avatar
        },
        game: row.game_name ? { name: row.game_name, icon: row.game_icon } : null,
        streamTitle: row.stream_title
      }
    });

  } catch (error) {
    console.error('Get clip error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch clip' });
  }
};

/**
 * Create a clip from live stream
 * @route POST /api/clips
 */
const createClip = async (req, res) => {
  try {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const { streamId, title, startTimestamp, endTimestamp, videoUrl, thumbnailUrl, gameId } = req.body;

    if (!title || !videoUrl) {
      return res.status(400).json({ success: false, error: 'Title and video URL are required' });
    }

    const duration = (endTimestamp || 0) - (startTimestamp || 0);

    const result = await db.query(
      `INSERT INTO clips (user_id, stream_id, title, video_url, thumbnail_url, duration, start_timestamp, end_timestamp, game_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING id, title, video_url, thumbnail_url, duration, created_at`,
      [userId, streamId || null, title, videoUrl, thumbnailUrl, duration, startTimestamp || 0, endTimestamp || 0, gameId || null]
    );

    const clip = result.rows[0];

    res.status(201).json({
      success: true,
      message: 'Clip created successfully',
      data: {
        id: clip.id,
        title: clip.title,
        videoUrl: clip.video_url,
        thumbnail: clip.thumbnail_url,
        duration: clip.duration,
        createdAt: clip.created_at
      }
    });

  } catch (error) {
    console.error('Create clip error:', error);
    res.status(500).json({ success: false, error: 'Failed to create clip' });
  }
};

/**
 * Like/unlike a clip
 * @route POST /api/clips/:id/like
 */
const toggleClipLike = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    // Check if already liked
    const existing = await db.query(
      'SELECT id FROM clip_likes WHERE clip_id = $1 AND user_id = $2',
      [id, userId]
    );

    let liked = false;
    if (existing.rows.length > 0) {
      // Unlike
      await db.query('DELETE FROM clip_likes WHERE clip_id = $1 AND user_id = $2', [id, userId]);
      await db.query('UPDATE clips SET likes_count = likes_count - 1 WHERE id = $1', [id]);
    } else {
      // Like
      await db.query('INSERT INTO clip_likes (clip_id, user_id) VALUES ($1, $2)', [id, userId]);
      await db.query('UPDATE clips SET likes_count = likes_count + 1 WHERE id = $1', [id]);
      liked = true;
    }

    // Get updated count
    const countResult = await db.query('SELECT likes_count FROM clips WHERE id = $1', [id]);

    res.json({
      success: true,
      data: {
        liked,
        likesCount: countResult.rows[0]?.likes_count || 0
      }
    });

  } catch (error) {
    console.error('Toggle clip like error:', error);
    res.status(500).json({ success: false, error: 'Failed to toggle like' });
  }
};

/**
 * Delete a clip
 * @route DELETE /api/clips/:id
 */
const deleteClip = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    // Check ownership
    const clip = await db.query('SELECT user_id FROM clips WHERE id = $1', [id]);
    if (clip.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Clip not found' });
    }
    if (clip.rows[0].user_id !== userId) {
      return res.status(403).json({ success: false, error: 'Not authorized to delete this clip' });
    }

    await db.query('DELETE FROM clips WHERE id = $1', [id]);

    res.json({ success: true, message: 'Clip deleted successfully' });

  } catch (error) {
    console.error('Delete clip error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete clip' });
  }
};

module.exports = {
  getClips,
  getClipById,
  getUserClips,
  createClip,
  toggleClipLike,
  deleteClip
};
