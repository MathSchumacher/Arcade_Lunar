import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/falling_stars.dart';

/// Live streaming screen with chat overlay and actions
class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = _mockMessages;
  bool _isLiked = false;
  int _likeCount = 12500;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        username: 'You',
        message: _chatController.text.trim(),
        isSystem: false,
      ));
      _chatController.clear();
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video placeholder (full screen)
          _buildVideoPlaceholder(),
          
          // Gradient overlay for readability
          _buildGradientOverlay(),
          
          // Safe area content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                const Spacer(),
                
                // Chat and actions row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Chat messages
                      Expanded(child: _buildChatOverlay()),
                      
                      const SizedBox(width: 12),
                      
                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
                
                // Chat input
                _buildChatInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Colors.orange.shade900,
            Colors.black,
          ],
        ),
      ),
      child: FallingStars(
        starCount: 50,
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange,
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0, 0.2, 0.6, 1],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Streamer info
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with live badge
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: const NetworkImage(
                        'https://i.pravatar.cc/100?img=33',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 10),
                
                // Name and rank
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'CosmicGamer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    Text(
                      'Rank: Nebula Walker',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Follow button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Follow',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Viewer count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '1.2k',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatOverlay() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        reverse: true,
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[_messages.length - 1 - index];
          return _buildChatMessage(message);
        },
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    if (message.isSystem) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'System',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              message.message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/50?u=${message.username}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.username,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: message.isGift ? Colors.amber : AppColors.secondary,
                  ),
                ),
                Text(
                  message.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // More options
        _buildActionButton(
          icon: Icons.more_horiz,
          onTap: () {},
        ),
        const SizedBox(height: 16),
        
        // Share
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        
        // Gift
        _buildActionButton(
          icon: Icons.card_giftcard,
          label: 'Gift',
          onTap: () {},
          color: AppColors.secondary,
        ),
        const SizedBox(height: 16),
        
        // Like
        _buildActionButton(
          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(_likeCount),
          onTap: _toggleLike,
          color: _isLiked ? Colors.red : null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? Colors.white,
              size: 22,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          // Input field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _chatController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Send a transmission...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    color: Colors.white.withOpacity(0.5),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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

class ChatMessage {
  final String username;
  final String message;
  final bool isSystem;
  final bool isGift;

  ChatMessage({
    required this.username,
    required this.message,
    this.isSystem = false,
    this.isGift = false,
  });
}

final List<ChatMessage> _mockMessages = [
  ChatMessage(
    username: 'System',
    message: 'Welcome to the Arcade Lunar! 🚀',
    isSystem: true,
  ),
  ChatMessage(
    username: 'LunaFan',
    message: 'GG WP! That was close.',
  ),
  ChatMessage(
    username: 'StarPilot_X',
    message: 'That combo was insane! 🔥\nCan you do it again?',
  ),
  ChatMessage(
    username: 'NebulaQueen',
    message: 'Sending a Meteor Gift! 🌠',
    isGift: true,
  ),
];
