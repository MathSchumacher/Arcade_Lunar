/**
 * Lives Controller
 * Handles live streams API requests
 * Note: Lives feature is mocked as "Coming Soon"
 */

const { lives } = require('../data/mockData');

/**
 * Get live streams (Coming Soon placeholder)
 * @route GET /api/lives
 */
const getLives = (req, res) => {
  try {
    res.json({
      success: true,
      data: lives.placeholder,
      meta: {
        message: lives.message,
        description: lives.description,
        isComingSoon: true
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch lives data'
    });
  }
};

module.exports = {
  getLives
};
