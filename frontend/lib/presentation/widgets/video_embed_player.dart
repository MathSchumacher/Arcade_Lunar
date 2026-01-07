import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Video Embed Player Widget
/// Displays embedded videos from YouTube, Instagram, TikTok
/// Shows thumbnail with play button overlay
class VideoEmbedPlayer extends StatefulWidget {
  final String? videoUrl;
  final String? videoType;
  final String? thumbnailUrl;
  final double? height;

  const VideoEmbedPlayer({
    super.key,
    this.videoUrl,
    this.videoType,
    this.thumbnailUrl,
    this.height,
  });

  @override
  State<VideoEmbedPlayer> createState() => _VideoEmbedPlayerState();
}

class _VideoEmbedPlayerState extends State<VideoEmbedPlayer> {
  bool _isPlaying = false;

  /// Get video ID from URL
  String? _getVideoId() {
    if (widget.videoUrl == null) return null;
    
    final url = widget.videoUrl!;
    
    // YouTube
    final youtubeMatch = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})'
    ).firstMatch(url);
    if (youtubeMatch != null) return youtubeMatch.group(1);
    
    // Instagram
    final instaMatch = RegExp(
      r'instagram\.com\/(?:p|reel|tv)\/([a-zA-Z0-9_-]+)'
    ).firstMatch(url);
    if (instaMatch != null) return instaMatch.group(1);
    
    return null;
  }

  /// Get thumbnail URL (auto-generate for YouTube)
  String _getThumbnail() {
    if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty) {
      return widget.thumbnailUrl!;
    }
    
    if (widget.videoType == 'youtube') {
      final videoId = _getVideoId();
      if (videoId != null) {
        return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      }
    }
    
    // Default placeholder
    return 'https://via.placeholder.com/640x360/1a1a2e/ffffff?text=Video';
  }

  /// Get platform icon
  IconData _getPlatformIcon() {
    switch (widget.videoType) {
      case 'youtube':
        return Icons.play_circle_filled;
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
      case 'twitch':
        return Icons.live_tv;
      default:
        return Icons.play_circle_outline;
    }
  }

  /// Get platform color
  Color _getPlatformColor() {
    switch (widget.videoType) {
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'instagram':
        return const Color(0xFFE1306C);
      case 'tiktok':
        return const Color(0xFF00F2EA);
      case 'twitch':
        return const Color(0xFF9146FF);
      default:
        return AppColors.primary;
    }
  }

  /// Open video in browser/app
  void _openVideo() {
    if (widget.videoUrl == null) return;
    
    // For now, show a snackbar - in production, use url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: ${widget.videoUrl}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
    
    // TODO: Implement with url_launcher package
    // launchUrl(Uri.parse(widget.videoUrl!));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoUrl == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _openVideo,
      child: Container(
        height: widget.height ?? 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            Image.network(
              _getThumbnail(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surface,
                child: Icon(
                  Icons.video_library,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            
            // Dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            
            // Play button
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _getPlatformColor(),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getPlatformColor().withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _getPlatformIcon(),
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            
            // Platform badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPlatformColor(),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.videoType?.toUpperCase() ?? 'VIDEO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            
            // Duration/info (bottom right)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.white.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to play',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
