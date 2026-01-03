/**
 * User Controller
 * Handles user-related API requests
 */

const { currentUser } = require('../data/mockData');

/**
 * Get current user profile
 * @route GET /api/user
 */
const getCurrentUser = (req, res) => {
  try {
    res.json({
      success: true,
      data: currentUser
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user data'
    });
  }
};

module.exports = {
  getCurrentUser
};
