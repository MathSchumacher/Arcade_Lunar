/**
 * Notifications Controller
 * Handles user notifications
 */

const db = require('../config/database');

/**
 * Get user's notifications
 * @route GET /api/notifications
 */
const getNotifications = async (req, res) => {
  try {
    const userId = req.user?.id;
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 30, 50);
    const offset = (page - 1) * limit;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const result = await db.query(
      `SELECT 
        n.id, n.type, n.message, n.reference_id, n.reference_type,
        n.is_read, n.created_at,
        u.id as from_user_id, u.username as from_username, u.avatar_url as from_avatar
      FROM notifications n
      LEFT JOIN users u ON n.from_user_id = u.id
      WHERE n.user_id = $1
      ORDER BY n.created_at DESC
      LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const notifications = result.rows.map(row => ({
      id: row.id,
      type: row.type,
      message: row.message,
      referenceId: row.reference_id,
      referenceType: row.reference_type,
      isRead: row.is_read,
      createdAt: row.created_at,
      fromUser: row.from_user_id ? {
        id: row.from_user_id,
        username: row.from_username,
        avatar: row.from_avatar
      } : null
    }));

    // Get unread count
    const unreadResult = await db.query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({
      success: true,
      data: notifications,
      meta: {
        page,
        limit,
        hasMore: notifications.length === limit,
        unreadCount: parseInt(unreadResult.rows[0].count)
      }
    });
  } catch (error) {
    console.error('getNotifications error:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch notifications' });
  }
};

/**
 * Mark notification as read
 * @route PUT /api/notifications/:id/read
 */
const markAsRead = async (req, res) => {
  try {
    const userId = req.user?.id;
    const notificationId = parseInt(req.params.id);

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    await db.query(
      'UPDATE notifications SET is_read = true WHERE id = $1 AND user_id = $2',
      [notificationId, userId]
    );

    res.json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    console.error('markAsRead error:', error);
    res.status(500).json({ success: false, error: 'Failed to mark notification as read' });
  }
};

/**
 * Mark all notifications as read
 * @route PUT /api/notifications/read-all
 */
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    await db.query(
      'UPDATE notifications SET is_read = true WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    console.error('markAllAsRead error:', error);
    res.status(500).json({ success: false, error: 'Failed to mark notifications as read' });
  }
};

/**
 * Get unread notification count
 * @route GET /api/notifications/count
 */
const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, error: 'Authentication required' });
    }

    const result = await db.query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false',
      [userId]
    );

    res.json({
      success: true,
      data: { unreadCount: parseInt(result.rows[0].count) }
    });
  } catch (error) {
    console.error('getUnreadCount error:', error);
    res.status(500).json({ success: false, error: 'Failed to get notification count' });
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  getUnreadCount
};
