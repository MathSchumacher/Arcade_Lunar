/**
 * Clips Controller
 * Handles quick clips API requests
 */

const { quickClips } = require('../data/mockData');

/**
 * Get quick clips
 * @route GET /api/clips
 */
const getClips = (req, res) => {
  try {
    // Sort by views (most popular first)
    const sortedClips = [...quickClips].sort((a, b) => b.views - a.views);

    res.json({
      success: true,
      data: sortedClips,
      meta: {
        total: quickClips.length
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch clips data'
    });
  }
};

/**
 * Get single clip by ID
 * @route GET /api/clips/:id
 */
const getClipById = (req, res) => {
  try {
    const { id } = req.params;
    const clip = quickClips.find(c => c.id === id);

    if (!clip) {
      return res.status(404).json({
        success: false,
        error: 'Clip not found'
      });
    }

    res.json({
      success: true,
      data: clip
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch clip'
    });
  }
};

module.exports = {
  getClips,
  getClipById
};
