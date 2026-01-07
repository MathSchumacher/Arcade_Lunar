/**
 * Trending Controller
 * Handles trending content API requests
 * Uses PostgreSQL database with mock data fallback for debug mode
 */

const db = require('../config/database');
const { trending: mockTrending, featuredEvent: mockFeaturedEvent } = require('../data/mockData');

const isDebugMode = process.env.NODE_ENV !== 'production';

/**
 * Get trending content (live streams by viewers)
 * @route GET /api/trending
 */
const getTrending = async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 20, 50);

    const result = await db.query(
      `SELECT 
        ls.id, ls.title, ls.thumbnail_url, ls.viewer_count, 
        ls.is_live, ls.started_at, ls.is_mock,
        u.id as streamer_id, u.username, u.avatar_url,
        up.display_name,
        gc.name as game_name

      FROM live_streams ls
      JOIN users u ON ls.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN game_categories gc ON ls.category_id = gc.id
      WHERE ls.is_live = true
      ORDER BY ls.viewer_count DESC
      LIMIT $1`,
      [limit]
    );

    // If no trending and debug mode, return mock
    if (result.rows.length === 0 && isDebugMode) {
      console.log('📦 No trending in DB, returning mock data (debug mode)');
      const sortedTrending = [...mockTrending].sort((a, b) => b.viewers - a.viewers);
      return res.json({
        success: true,
        data: sortedTrending,
        meta: {
          total: mockTrending.length,
          liveCount: mockTrending.filter(t => t.isLive).length,
          source: 'mock'
        }
      });
    }

    const trending = result.rows.map(row => ({
      id: row.id,
      title: row.title,
      streamer: row.display_name || row.username,
      streamerId: row.streamer_id,
      streamerAvatar: row.avatar_url,
      thumbnail: row.thumbnail_url || 'https://images.unsplash.com/photo-1542751110-97427bbecf20?w=400&q=80',
      viewers: row.viewer_count,
      isLive: row.is_live,
      game: row.game_name,
      isMock: row.is_mock,
      duration: _formatDuration(row.started_at)
    }));

    res.json({
      success: true,
      data: trending,
      meta: {
        total: trending.length,
        liveCount: trending.filter(t => t.isLive).length,
        source: 'database'
      }
    });
  } catch (error) {
    console.error('getTrending error:', error);
    
    if (isDebugMode) {
      console.log('⚠️ Database error, falling back to mock data');
      return res.json({
        success: true,
        data: mockTrending,
        meta: {
          total: mockTrending.length,
          liveCount: mockTrending.filter(t => t.isLive).length,
          source: 'mock_fallback'
        }
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch trending data'
    });
  }
};

/**
 * Get featured event
 * @route GET /api/featured
 */
const getFeaturedEvent = async (req, res) => {
  try {
    // For now, return mock featured event
    // In production, this would come from a featured_events table
    res.json({
      success: true,
      data: {
        id: 'event_001',
        title: 'Cosmic Cup Finals',
        subtitle: 'Win exclusive badges & XP boost',
        backgroundImage: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&q=80',
        endTime: new Date(Date.now() + 2 * 60 * 60 * 1000 + 45 * 60 * 1000).toISOString(),
        prizes: ['Exclusive Badge', '500 XP', 'Cosmic Skin'],
        isActive: true
      }
    });
  } catch (error) {
    console.error('getFeaturedEvent error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch featured event'
    });
  }
};

/**
 * Format stream duration from start time
 */
function _formatDuration(startedAt) {
  if (!startedAt) return '0:00';
  
  const diff = Date.now() - new Date(startedAt).getTime();
  const hours = Math.floor(diff / (1000 * 60 * 60));
  const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
  const seconds = Math.floor((diff % (1000 * 60)) / 1000);
  
  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
}

module.exports = {
  getTrending,
  getFeaturedEvent
};
