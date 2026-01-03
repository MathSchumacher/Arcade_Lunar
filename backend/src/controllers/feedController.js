/**
 * Feed Controller
 * Handles social feed API requests
 */

const { feed } = require('../data/mockData');

/**
 * Get social feed posts
 * @route GET /api/feed
 */
const getFeed = (req, res) => {
  try {
    // Sort by creation date (newest first)
    const sortedFeed = [...feed].sort((a, b) => 
      new Date(b.createdAt) - new Date(a.createdAt)
    );

    res.json({
      success: true,
      data: sortedFeed,
      meta: {
        total: feed.length,
        hasMore: false // For pagination support later
      }
    });
  } catch (error) {
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
const getPostById = (req, res) => {
  try {
    const { id } = req.params;
    const post = feed.find(p => p.id === id);

    if (!post) {
      return res.status(404).json({
        success: false,
        error: 'Post not found'
      });
    }

    res.json({
      success: true,
      data: post
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch post'
    });
  }
};

module.exports = {
  getFeed,
  getPostById
};
