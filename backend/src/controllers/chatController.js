/**
 * Chat Controller
 * Handles stream chat messages
 */

const db = require('../config/database');

/**
 * Get chat messages for a stream
 * @route GET /api/streams/:streamId/chat
 */
const getMessages = async (req, res) => {
  try {
    const { streamId } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const before = req.query.before; // For pagination

    let query = `
      SELECT 
        cm.id, cm.message, cm.emotes, cm.created_at,
        u.id as user_id, u.username, u.avatar_url, u.is_verified,
        up.display_name
      FROM chat_messages cm
      JOIN users u ON cm.user_id = u.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE cm.stream_id = $1 AND cm.is_deleted = false
    `;

    const params = [streamId];

    if (before) {
      query += ` AND cm.id < $${params.length + 1}`;
      params.push(before);
    }

    query += ` ORDER BY cm.created_at DESC LIMIT $${params.length + 1}`;
    params.push(limit);

    const result = await db.query(query, params);

    const messages = result.rows.map(row => ({
      id: row.id,
      message: row.message,
      emotes: row.emotes || [],
      createdAt: row.created_at,
      user: {
        id: row.user_id,
        username: row.username,
        displayName: row.display_name || row.username,
        avatar: row.avatar_url,
        isVerified: row.is_verified
      }
    })).reverse(); // Reverse to get chronological order

    res.json({
      success: true,
      data: messages,
      meta: {
        streamId: parseInt(streamId),
        count: messages.length,
        hasMore: messages.length === limit
      }
    });
  } catch (error) {
    console.error('getMessages error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch messages' });
  }
};

/**
 * Send a chat message
 * @route POST /api/streams/:streamId/chat
 */
const sendMessage = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { streamId } = req.params;
    const { message, emotes } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    if (!message || message.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Message cannot be empty' });
    }

    if (message.length > 500) {
      return res.status(400).json({ success: false, error: 'Message too long (max 500 characters)' });
    }

    const result = await db.query(
      `INSERT INTO chat_messages (stream_id, user_id, message, emotes)
       VALUES ($1, $2, $3, $4)
       RETURNING id, message, emotes, created_at`,
      [streamId, userId, message.trim(), JSON.stringify(emotes || [])]
    );

    // Get user info
    const userResult = await db.query(
      `SELECT u.username, u.avatar_url, u.is_verified, up.display_name
       FROM users u
       LEFT JOIN user_profiles up ON u.id = up.user_id
       WHERE u.id = $1`,
      [userId]
    );

    const row = result.rows[0];
    const userRow = userResult.rows[0];

    res.status(201).json({
      success: true,
      data: {
        id: row.id,
        message: row.message,
        emotes: row.emotes || [],
        createdAt: row.created_at,
        user: {
          id: userId,
          username: userRow.username,
          displayName: userRow.display_name || userRow.username,
          avatar: userRow.avatar_url,
          isVerified: userRow.is_verified
        }
      }
    });
  } catch (error) {
    console.error('sendMessage error:', error);
    res.status(500).json({ success: false, error: 'Failed to send message' });
  }
};

/**
 * Delete a chat message (by streamer or message sender)
 * @route DELETE /api/streams/:streamId/chat/:messageId
 */
const deleteMessage = async (req, res) => {
  try {
    const userId = req.user?.id;
    const { streamId, messageId } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    // Check if user is message sender or stream owner
    const result = await db.query(
      `UPDATE chat_messages cm
       SET is_deleted = true
       WHERE cm.id = $1 AND cm.stream_id = $2
         AND (cm.user_id = $3 OR EXISTS (
           SELECT 1 FROM live_streams ls WHERE ls.id = $2 AND ls.user_id = $3
         ))
       RETURNING id`,
      [messageId, streamId, userId]
    );

    if (result.rows.length === 0) {
      return res.status(403).json({ success: false, error: 'Cannot delete this message' });
    }

    res.json({ success: true, message: 'Message deleted' });
  } catch (error) {
    console.error('deleteMessage error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete message' });
  }
};

module.exports = {
  getMessages,
  sendMessage,
  deleteMessage
};
