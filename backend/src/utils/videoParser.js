/**
 * Video URL Parser Utility
 * Extracts video info from YouTube, Instagram, TikTok URLs
 */

/**
 * Detect video type from URL
 * @param {string} url - Video URL
 * @returns {object|null} - { type, videoId, embedUrl, thumbnail }
 */
const parseVideoUrl = (url) => {
  if (!url) return null;

  // YouTube patterns
  const youtubePatterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})/,
    /youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})/
  ];

  for (const pattern of youtubePatterns) {
    const match = url.match(pattern);
    if (match) {
      const videoId = match[1];
      return {
        type: 'youtube',
        videoId,
        embedUrl: `https://www.youtube.com/embed/${videoId}`,
        thumbnail: `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`
      };
    }
  }

  // Instagram patterns
  const instagramPatterns = [
    /instagram\.com\/(?:p|reel|tv)\/([a-zA-Z0-9_-]+)/,
    /instagr\.am\/(?:p|reel|tv)\/([a-zA-Z0-9_-]+)/
  ];

  for (const pattern of instagramPatterns) {
    const match = url.match(pattern);
    if (match) {
      const videoId = match[1];
      return {
        type: 'instagram',
        videoId,
        embedUrl: `https://www.instagram.com/p/${videoId}/embed`,
        thumbnail: null // Instagram doesn't provide easy thumbnail access
      };
    }
  }

  // TikTok patterns
  const tiktokPatterns = [
    /tiktok\.com\/@[\w.]+\/video\/(\d+)/,
    /vm\.tiktok\.com\/([a-zA-Z0-9]+)/
  ];

  for (const pattern of tiktokPatterns) {
    const match = url.match(pattern);
    if (match) {
      const videoId = match[1];
      return {
        type: 'tiktok',
        videoId,
        embedUrl: `https://www.tiktok.com/embed/${videoId}`,
        thumbnail: null
      };
    }
  }

  // Twitch clip patterns
  const twitchPatterns = [
    /clips\.twitch\.tv\/([a-zA-Z0-9_-]+)/,
    /twitch\.tv\/\w+\/clip\/([a-zA-Z0-9_-]+)/
  ];

  for (const pattern of twitchPatterns) {
    const match = url.match(pattern);
    if (match) {
      const clipId = match[1];
      return {
        type: 'twitch',
        videoId: clipId,
        embedUrl: `https://clips.twitch.tv/embed?clip=${clipId}&parent=localhost`,
        thumbnail: null
      };
    }
  }

  return null;
};

/**
 * Extract video URL from post content
 * @param {string} content - Post text content
 * @returns {string|null} - First video URL found
 */
const extractVideoUrl = (content) => {
  if (!content) return null;
  
  const urlPattern = /(https?:\/\/[^\s]+)/g;
  const urls = content.match(urlPattern) || [];
  
  for (const url of urls) {
    const parsed = parseVideoUrl(url);
    if (parsed) {
      return url;
    }
  }
  
  return null;
};

/**
 * Process post content for video embeds
 * @param {string} content - Post text
 * @param {string} explicitVideoUrl - Optional explicit video URL
 * @returns {object} - { videoUrl, videoType, videoThumbnail }
 */
const processPostVideo = (content, explicitVideoUrl = null) => {
  const url = explicitVideoUrl || extractVideoUrl(content);
  
  if (!url) {
    return { videoUrl: null, videoType: null, videoThumbnail: null };
  }

  const parsed = parseVideoUrl(url);
  
  if (parsed) {
    return {
      videoUrl: url,
      videoType: parsed.type,
      videoThumbnail: parsed.thumbnail,
      embedUrl: parsed.embedUrl,
      videoId: parsed.videoId
    };
  }

  return { videoUrl: url, videoType: 'other', videoThumbnail: null };
};

module.exports = {
  parseVideoUrl,
  extractVideoUrl,
  processPostVideo
};
