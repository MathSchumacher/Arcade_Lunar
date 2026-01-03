/**
 * Friends Controller
 * Handles friends-related API requests
 */

const { friends } = require('../data/mockData');

/**
 * Get online friends list
 * @route GET /api/friends
 */
const getFriends = (req, res) => {
  try {
    // Filter online friends first, then offline
    const sortedFriends = [...friends].sort((a, b) => {
      if (a.isOnline === b.isOnline) return 0;
      return a.isOnline ? -1 : 1;
    });

    res.json({
      success: true,
      data: sortedFriends,
      meta: {
        total: friends.length,
        online: friends.filter(f => f.isOnline).length
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch friends data'
    });
  }
};

module.exports = {
  getFriends
};
