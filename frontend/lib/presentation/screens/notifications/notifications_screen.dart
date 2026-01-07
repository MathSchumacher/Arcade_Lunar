import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/user_avatar.dart';

/// Full notifications screen with different notification types
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    try {
      final data = await ApiService.getNotifications();
      if (data.isNotEmpty && mounted) {
        setState(() {
          _notifications = data.map((n) => NotificationItem(
            id: n['id'],
            type: _parseType(n['type']),
            username: n['fromUser']?['username'] ?? 'Unknown',
            avatar: n['fromUser']?['avatar'] ?? 'https://picsum.photos/100',
            message: n['message'] ?? '',
            timestamp: _formatTimestamp(n['createdAt']),
            isUnread: !(n['isRead'] ?? false),
          )).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Failed to load notifications: $e');
    }
    
    // Fallback to mock data
    if (mounted) {
      setState(() {
        _notifications = [
          NotificationItem(type: NotificationType.live, username: 'NinjaLunar', avatar: 'https://picsum.photos/seed/ninja/100/100', message: 'started a live stream', timestamp: '2m ago', isUnread: true),
          NotificationItem(type: NotificationType.follow, username: 'ProGamer92', avatar: 'https://picsum.photos/seed/progamer/100/100', message: 'started following you', timestamp: '15m ago', isUnread: true),
          NotificationItem(type: NotificationType.like, username: 'GamerGirl', avatar: 'https://picsum.photos/seed/gamergirl/100/100', message: 'liked your post', timestamp: '1h ago', isUnread: true),
          NotificationItem(type: NotificationType.comment, username: 'StreamerKing', avatar: 'https://picsum.photos/seed/streamer/100/100', message: 'commented: "Great content!"', timestamp: '2h ago', isUnread: false),
          NotificationItem(type: NotificationType.follow, username: 'PixelWarrior', avatar: 'https://picsum.photos/seed/pixel/100/100', message: 'started following you', timestamp: '1d ago', isUnread: false),
        ];
        _isLoading = false;
      });
    }
  }
  
  NotificationType _parseType(String? type) {
    switch (type) {
      case 'live': return NotificationType.live;
      case 'follow': return NotificationType.follow;
      case 'like': return NotificationType.like;
      case 'comment': return NotificationType.comment;
      case 'mention': return NotificationType.mention;
      default: return NotificationType.follow;
    }
  }
  
  String _formatTimestamp(String? dateStr) {
    if (dateStr == null) return 'now';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (e) {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _notifications.length,
                itemBuilder: (context, index) => _buildNotificationTile(_notifications[index]),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    return InkWell(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: notification.isUnread ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                UserAvatar(imageUrl: notification.avatar, size: 50),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Icon(_getNotificationIcon(notification.type), size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: notification.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        TextSpan(text: ' ${notification.message}', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(notification.timestamp, style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            if (notification.type == NotificationType.live)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_arrow, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Watch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            if (notification.isUnread && notification.type != NotificationType.live)
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.live: return Icons.videocam;
      case NotificationType.follow: return Icons.person_add;
      case NotificationType.like: return Icons.favorite;
      case NotificationType.comment: return Icons.chat_bubble;
      case NotificationType.mention: return Icons.alternate_email;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.live: return Colors.red;
      case NotificationType.follow: return AppColors.primary;
      case NotificationType.like: return Colors.pink;
      case NotificationType.comment: return AppColors.secondary;
      case NotificationType.mention: return Colors.orange;
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    setState(() => notification.isUnread = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(notification.type == NotificationType.live 
        ? '🔴 Opening ${notification.username}\'s stream...' 
        : 'Opening ${notification.username}\'s profile...')),
    );
  }

  void _markAllAsRead() async {
    setState(() {
      for (var n in _notifications) n.isUnread = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read')));
    
    // Call API
    await ApiService.markAllNotificationsRead();
  }
}

enum NotificationType { live, follow, like, comment, mention }

class NotificationItem {
  final int? id;
  final NotificationType type;
  final String username;
  final String avatar;
  final String message;
  final String timestamp;
  bool isUnread;

  NotificationItem({
    this.id,
    required this.type,
    required this.username,
    required this.avatar,
    required this.message,
    required this.timestamp,
    required this.isUnread,
  });
}
