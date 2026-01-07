import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/post_model.dart';
import '../../data/services/api_service.dart';
import 'user_avatar.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCommentTap;

  const PostCard({
    super.key,
    required this.post,
    this.onProfileTap,
    this.onCommentTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  late bool _isBookmarked;
  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likes;
    _isBookmarked = false;

    _likeAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _likeAnimController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    // Optimistic update
    final wasLiked = _isLiked;
    final previousCount = _likeCount;
    
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    
    // Animate
    _likeAnimController.forward().then((_) => _likeAnimController.reverse());
    
    // Call backend API
    try {
      final postId = int.tryParse(widget.post.id.toString());
      if (postId != null) {
        final result = await ApiService.toggleLike(postId);
        if (result != null) {
          // Update with server values
          setState(() {
            _isLiked = result['isLiked'] ?? _isLiked;
            _likeCount = result['likesCount'] ?? _likeCount;
          });
        }
      }
    } catch (e) {
      // Rollback on error
      setState(() {
        _isLiked = wasLiked;
        _likeCount = previousCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update like'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleBookmark() async {
    final wasSaved = _isBookmarked;
    
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? '📌 Saved to bookmarks' : 'Removed from bookmarks'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Call backend API
    try {
      final postId = int.tryParse(widget.post.id.toString());
      if (postId != null) {
        final success = _isBookmarked
            ? await ApiService.savePost(postId)
            : await ApiService.unsavePost(postId);
        
        if (!success && mounted) {
          // Rollback on failure
          setState(() => _isBookmarked = wasSaved);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update bookmark'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      // Rollback on error
      if (mounted) {
        setState(() => _isBookmarked = wasSaved);
      }
    }
  }

  void _sharePost() {
    // Share.share(
    //   '${widget.post.author.username}: ${widget.post.content}\n\n📲 via Arcade Lunar',
    //   subject: 'Check this post on Arcade Lunar!',
    // );
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _CommentsSheet(
          post: widget.post,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: widget.post.author.avatar,
                  size: 40,
                  isOnline: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.author.username,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (widget.post.author.badge != null)
                        Text(
                          widget.post.author.badge!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  onPressed: () => _showPostOptions(),
                ),
              ],
            ),
          ),

          // Content
          const SizedBox(height: 12),
          Text(
            widget.post.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),

          // Images (double tap to like)
          if (widget.post.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onDoubleTap: () {
                if (!_isLiked) _toggleLike();
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: widget.post.images.first,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200,
                    color: AppColors.surface,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: AppColors.surface,
                    child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ],

          // Actions
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Like button with animation
              ScaleTransition(
                scale: _likeScaleAnimation,
                child: _ActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(_likeCount),
                  color: _isLiked ? AppColors.error : AppColors.textSecondary,
                  onTap: _toggleLike,
                ),
              ),
              // Comment button
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: _formatCount(widget.post.comments),
                onTap: _openComments,
              ),
              // Share button
              _ActionButton(
                icon: Icons.share_outlined,
                label: '',
                onTap: _sharePost,
              ),
              // Bookmark button
              IconButton(
                icon: Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: _isBookmarked ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: _toggleBookmark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.white),
              title: const Text('Follow', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Following ${widget.post.author.username}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.orange),
              title: const Text('Report', style: TextStyle(color: Colors.orange)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post reported')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? AppColors.textSecondary,
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

/// Comments bottom sheet
class _CommentsSheet extends StatefulWidget {
  final Post post;
  final ScrollController scrollController;

  const _CommentsSheet({required this.post, required this.scrollController});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  final List<Map<String, dynamic>> _comments = [
    {'user': 'gamer_pro', 'text': 'Amazing content! 🔥', 'time': '2m'},
    {'user': 'lunar_fan', 'text': 'Love this!', 'time': '5m'},
    {'user': 'streamer123', 'text': 'Keep it up 💪', 'time': '12m'},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() {
      _comments.insert(0, {
        'user': 'you',
        'text': _commentController.text.trim(),
        'time': 'now',
      });
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.2))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comments (${widget.post.comments + _comments.length})',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        
        // Comments list
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        comment['user'][0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '@${comment['user']}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                comment['time'],
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(comment['text'], style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border, size: 16, color: AppColors.textSecondary),
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        // Comment input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.primary.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _addComment,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
