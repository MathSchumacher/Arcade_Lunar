/**
 * Trending Controller
 * Handles trending content API requests
 */

const { trending, featuredEvent } = require('../data/mockData');

/**
 * Get trending content
 * @route GET /api/trending
 */
const getTrending = (req, res) => {
  try {
    // Sort by viewers (most popular first)
    const sortedTrending = [...trending].sort((a, b) => b.viewers - a.viewers);

    res.json({
      success: true,
      data: sortedTrending,
      meta: {
        total: trending.length,
        liveCount: trending.filter(t => t.isLive).length
      }
    });
  } catch (error) {
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
const getFeaturedEvent = (req, res) => {
  try {
    res.json({
      success: true,
      data: featuredEvent
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch featured event'
    });
  }
};

module.exports = {
  getTrending,
  getFeaturedEvent
};
