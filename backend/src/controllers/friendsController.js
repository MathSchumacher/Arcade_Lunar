/**
 * Friends Controller
 * Handles friends-related API requests
 * Uses PostgreSQL database with mock data fallback for debug mode
 */

const db = require('../config/database');
const { friends: mockFriends } = require('../data/mockData');

const isDebugMode = process.env.NODE_ENV !== 'production';

/**
 * Get friends list for current user
 * @route GET /api/friends
 */
const getFriends = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      // Return mock data for unauthenticated users in debug mode
      if (isDebugMode) {
        const sortedFriends = [...mockFriends].sort((a, b) => {
          if (a.isOnline === b.isOnline) return 0;
          return a.isOnline ? -1 : 1;
        });

        return res.json({
          success: true,
          data: sortedFriends,
          meta: {
            total: mockFriends.length,
            online: mockFriends.filter(f => f.isOnline).length,
            source: 'mock'
          }
        });
      }
      
      return res.status(401).json({
        success: false,
        error: 'Authentication required'
      });
    }

    // Get accepted friends from database
    const result = await db.query(
      `SELECT 
        u.id, u.username, u.avatar_url, u.is_verified,
        up.display_name, up.bio,
        f.created_at as friends_since,
        -- Check if friend is currently streaming
        CASE WHEN ls.is_live = true THEN true ELSE false END as is_streaming,
        ls.title as stream_title,
        gc.name as stream_game
      FROM friends f
      JOIN users u ON (
        CASE WHEN f.user_id = $1 THEN f.friend_id ELSE f.user_id END
      ) = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN live_streams ls ON u.id = ls.user_id AND ls.is_live = true
      LEFT JOIN game_categories gc ON ls.category_id = gc.id
      WHERE (f.user_id = $1 OR f.friend_id = $1) 
        AND f.status = 'accepted'
        AND u.id != $1
      ORDER BY ls.is_live DESC NULLS LAST, u.username ASC`,
      [userId]
    );

    // If no friends and debug mode, merge with mock
    if (result.rows.length === 0 && isDebugMode) {
      console.log('📦 No friends in DB, returning mock data (debug mode)');
      const sortedFriends = [...mockFriends].sort((a, b) => {
        if (a.isOnline === b.isOnline) return 0;
        return a.isOnline ? -1 : 1;
      });

      return res.json({
        success: true,
        data: sortedFriends,
        meta: {
          total: mockFriends.length,
          online: mockFriends.filter(f => f.isOnline).length,
          source: 'mock'
        }
      });
    }

    const friends = result.rows.map(row => ({
      id: row.id,
      username: row.username,
      displayName: row.display_name || row.username,
      avatar: row.avatar_url,
      isOnline: row.is_streaming || false, // Consider streaming as online
      isStreaming: row.is_streaming,
      status: row.is_streaming ? `Streaming ${row.stream_game}` : 'Online',
      game: row.stream_game,
      streamTitle: row.stream_title,
      isVerified: row.is_verified
    }));

    res.json({
      success: true,
      data: friends,
      meta: {
        total: friends.length,
        online: friends.filter(f => f.isOnline).length,
        source: 'database'
      }
    });
  } catch (error) {
    console.error('getFriends error:', error);
    
    if (isDebugMode) {
      console.log('⚠️ Database error, falling back to mock data');
      return res.json({
        success: true,
        data: mockFriends,
        meta: {
          total: mockFriends.length,
          online: mockFriends.filter(f => f.isOnline).length,
          source: 'mock_fallback'
        }
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Failed to fetch friends data'
    });
  }
};

/**
 * Send friend request
 * @route POST /api/friends/:userId
 */
const addFriend = async (req, res) => {
  try {
    const userId = req.user?.id;
    const friendId = parseInt(req.params.userId);

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    if (userId === friendId) {
      return res.status(400).json({ success: false, error: 'Cannot add yourself as friend' });
    }

    // Check if friendship already exists
    const existing = await db.query(
      `SELECT id, status FROM friends 
       WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)`,
      [userId, friendId]
    );

    if (existing.rows.length > 0) {
      return res.status(400).json({ 
        success: false, 
        error: 'Friend request already exists',
        status: existing.rows[0].status
      });
    }

    // Create friend request
    await db.query(
      `INSERT INTO friends (user_id, friend_id, status) VALUES ($1, $2, 'pending')`,
      [userId, friendId]
    );

    res.status(201).json({
      success: true,
      message: 'Friend request sent'
    });
  } catch (error) {
    console.error('addFriend error:', error);
    res.status(500).json({ success: false, error: 'Failed to send friend request' });
  }
};

/**
 * Accept/reject friend request
 * @route PUT /api/friends/:userId
 */
const updateFriend = async (req, res) => {
  try {
    const userId = req.user?.id;
    const friendId = parseInt(req.params.userId);
    const { status } = req.body; // 'accepted' or 'blocked'

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    if (!['accepted', 'blocked'].includes(status)) {
      return res.status(400).json({ success: false, error: 'Invalid status' });
    }

    const result = await db.query(
      `UPDATE friends SET status = $3 
       WHERE user_id = $2 AND friend_id = $1 AND status = 'pending'
       RETURNING id`,
      [userId, friendId, status]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Friend request not found' });
    }

    res.json({
      success: true,
      message: status === 'accepted' ? 'Friend request accepted' : 'Friend request rejected'
    });
  } catch (error) {
    console.error('updateFriend error:', error);
    res.status(500).json({ success: false, error: 'Failed to update friend request' });
  }
};

/**
 * Remove friend
 * @route DELETE /api/friends/:userId
 */
const removeFriend = async (req, res) => {
  try {
    const userId = req.user?.id;
    const friendId = parseInt(req.params.userId);

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    await db.query(
      `DELETE FROM friends 
       WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)`,
      [userId, friendId]
    );

    res.json({
      success: true,
      message: 'Friend removed'
    });
  } catch (error) {
    console.error('removeFriend error:', error);
    res.status(500).json({ success: false, error: 'Failed to remove friend' });
  }
};

module.exports = {
  getFriends,
  addFriend,
  updateFriend,
  removeFriend
};
