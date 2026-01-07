/**
 * Lives Controller
 * Handles live streams API requests
 * Uses PostgreSQL database with mock data fallback for debug mode
 */

const db = require('../config/database');

const isDebugMode = process.env.NODE_ENV !== 'production';

// Mock live data for fallback
const mockLives = [
  {
    id: 1,
    title: '🔥 Ranked Grind to Immortal!',
    streamer: { id: 1, username: 'CosmicPlayer', displayName: 'CosmicPlayer', avatar: 'https://picsum.photos/seed/cosmic/150/150' },
    game: 'Valorant',
    viewers: 12543,
    isLive: true,
    thumbnail: 'https://images.unsplash.com/photo-1542751110-97427bbecf20?w=400&q=80',
    startedAt: new Date(Date.now() - 60 * 60 * 1000).toISOString()
  },
  {
    id: 2,
    title: 'Diamond promos today! 💎',
    streamer: { id: 2, username: 'LunarGirl', displayName: 'LunarGirl', avatar: 'https://picsum.photos/seed/lunargirl/150/150' },
    game: 'League of Legends',
    viewers: 8921,
    isLive: true,
    thumbnail: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=400&q=80',
    startedAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 3,
    title: 'AWP Only Challenge 🎯',
    streamer: { id: 3, username: 'ProSniper', displayName: 'ProSniper', avatar: 'https://picsum.photos/seed/prosniper/150/150' },
    game: 'Counter-Strike 2',
    viewers: 21098,
    isLive: true,
    thumbnail: 'https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=400&q=80',
    startedAt: new Date(Date.now() - 30 * 60 * 1000).toISOString()
  },
  {
    id: 4,
    title: 'Construindo mega castelo! 🏰',
    streamer: { id: 4, username: 'Alanzoka', displayName: 'Alanzoka', avatar: 'https://picsum.photos/seed/alanzoka/150/150' },
    game: 'Minecraft',
    viewers: 45000,
    isLive: true,
    thumbnail: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&q=80',
    startedAt: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString()
  },
  {
    id: 5,
    title: 'Treino FPL - Road to Major',
    streamer: { id: 5, username: 'Gaulles', displayName: 'Gaulês', avatar: 'https://picsum.photos/seed/gaulles/150/150' },
    game: 'Counter-Strike 2',
    viewers: 32000,
    isLive: true,
    thumbnail: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&q=80',
    startedAt: new Date(Date.now() - 60 * 60 * 1000).toISOString()
  }
];

/**
 * Get live streams
 * @route GET /api/lives
 */
const getLives = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);
    const offset = (page - 1) * limit;
    const categorySlug = req.query.category;
    const userId = req.user?.id;

    let query = `
      SELECT 
        ls.id, ls.title, ls.thumbnail_url, ls.viewer_count, 
        ls.is_live, ls.started_at, ls.is_mock,
        u.id as streamer_id, u.username, u.avatar_url, u.is_verified,
        up.display_name,
        gc.name as game_name, gc.slug as game_slug,
        CASE WHEN f.follower_id IS NOT NULL THEN true ELSE false END as is_followed
      FROM live_streams ls
      JOIN users u ON ls.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN game_categories gc ON ls.category_id = gc.id
      LEFT JOIN follows f ON ls.user_id = f.following_id AND f.follower_id = $1
      WHERE ls.is_live = true
    `;

    const params = [userId || 0];

    if (categorySlug) {
      query += ` AND gc.slug = $${params.length + 1}`;
      params.push(categorySlug);
    }

    query += ` ORDER BY ls.viewer_count DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    // If no streams and debug mode, return mock data
    if (result.rows.length === 0 && isDebugMode) {
      console.log('📦 No live streams in DB, returning mock data (debug mode)');
      return res.json({
        success: true,
        data: mockLives,
        meta: {
          total: mockLives.length,
          page,
          limit,
          hasMore: false,
          source: 'mock'
        }
      });
    }

    const streams = result.rows.map(row => ({
      id: row.id,
      title: row.title,
      thumbnail: row.thumbnail_url,
      viewers: row.viewer_count,
      isLive: row.is_live,
      startedAt: row.started_at,
      isMock: row.is_mock,
      game: row.game_name,
      gameSlug: row.game_slug,
      isFollowed: row.is_followed,
      streamer: {
        id: row.streamer_id,
        username: row.username,
        displayName: row.display_name || row.username,
        avatar: row.avatar_url,
        isVerified: row.is_verified
      }
    }));

    res.json({
      success: true,
      data: streams,
      meta: {
        total: streams.length,
        page,
        limit,
        hasMore: streams.length === limit,
        source: 'database'
      }
    });
  } catch (error) {
    console.error('getLives error:', error);
    
    if (isDebugMode) {
      console.log('⚠️ Database error, falling back to mock data');
      return res.json({
        success: true,
        data: mockLives,
        meta: {
          total: mockLives.length,
          hasMore: false,
          source: 'mock_fallback'
        }
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lives data'
    });
  }
};

/**
 * Get single live stream by ID
 * @route GET /api/lives/:id
 */
const getLiveById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id;

    const result = await db.query(
      `SELECT 
        ls.id, ls.title, ls.thumbnail_url, ls.viewer_count, 
        ls.is_live, ls.started_at,
        u.id as streamer_id, u.username, u.avatar_url, u.is_verified,
        up.display_name, up.bio,
        gc.name as game_name, gc.slug as game_slug,
        CASE WHEN f.follower_id IS NOT NULL THEN true ELSE false END as is_followed
      FROM live_streams ls
      JOIN users u ON ls.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN game_categories gc ON ls.category_id = gc.id
      LEFT JOIN follows f ON ls.user_id = f.following_id AND f.follower_id = $2
      WHERE ls.id = $1`,
      [id, userId || 0]
    );

    if (result.rows.length === 0) {
      // Try mock data
      if (isDebugMode) {
        const stream = mockLives.find(s => s.id === parseInt(id));
        if (stream) {
          return res.json({ success: true, data: stream, source: 'mock' });
        }
      }
      
      return res.status(404).json({
        success: false,
        error: 'Stream not found'
      });
    }

    const row = result.rows[0];
    res.json({
      success: true,
      data: {
        id: row.id,
        title: row.title,
        thumbnail: row.thumbnail_url,
        viewers: row.viewer_count,
        isLive: row.is_live,
        startedAt: row.started_at,
        game: row.game_name,
        gameSlug: row.game_slug,
        isFollowed: row.is_followed,
        streamer: {
          id: row.streamer_id,
          username: row.username,
          displayName: row.display_name || row.username,
          avatar: row.avatar_url,
          isVerified: row.is_verified,
          bio: row.bio
        }
      }
    });
  } catch (error) {
    console.error('getLiveById error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch stream'
    });
  }
};

/**
 * Get streams from followed users
 * @route GET /api/lives/following
 */
const getFollowingLives = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const result = await db.query(
      `SELECT 
        ls.id, ls.title, ls.thumbnail_url, ls.viewer_count, 
        ls.is_live, ls.started_at,
        u.id as streamer_id, u.username, u.avatar_url, u.is_verified,
        up.display_name,
        gc.name as game_name
      FROM live_streams ls
      JOIN users u ON ls.user_id = u.id
      JOIN follows f ON ls.user_id = f.following_id AND f.follower_id = $1
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN game_categories gc ON ls.category_id = gc.id
      WHERE ls.is_live = true
      ORDER BY ls.viewer_count DESC`,
      [userId]
    );

    const streams = result.rows.map(row => ({
      id: row.id,
      title: row.title,
      thumbnail: row.thumbnail_url,
      viewers: row.viewer_count,
      isLive: row.is_live,
      startedAt: row.started_at,
      game: row.game_name,
      streamer: {
        id: row.streamer_id,
        username: row.username,
        displayName: row.display_name || row.username,
        avatar: row.avatar_url,
        isVerified: row.is_verified
      }
    }));

    res.json({
      success: true,
      data: streams,
      meta: {
        total: streams.length
      }
    });
  } catch (error) {
    console.error('getFollowingLives error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch followed streams'
    });
  }
};

module.exports = {
  getLives,
  getLiveById,
  getFollowingLives
};
