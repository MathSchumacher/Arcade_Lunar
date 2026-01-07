import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/mock_data_service.dart';
import '../../../data/services/api_service.dart';

/// Stream Viewer Screen - Watch live streams with interactions
class StreamViewerScreen extends StatefulWidget {
  final MockStreamer streamer;

  const StreamViewerScreen({super.key, required this.streamer});

  @override
  State<StreamViewerScreen> createState() => _StreamViewerScreenState();
}

class _StreamViewerScreenState extends State<StreamViewerScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _showGiftPanel = false;

  @override
  void initState() {
    super.initState();
    // Load chat messages from API (with mock fallback)
    _loadChatMessages();
    // Landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  Future<void> _loadChatMessages() async {
    try {
      final streamId = int.tryParse(widget.streamer.id.toString());
      if (streamId != null) {
        final messages = await ApiService.getChatMessages(streamId);
        if (messages.isNotEmpty && mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(messages.map((m) => ChatMessage(
              m['user']?['username'] ?? 'Anonymous',
              m['message'] ?? '',
            )));
          });
          return;
        }
      }
    } catch (e) {
      print('Failed to load chat: $e');
    }
    
    // Fallback to mock messages
    if (mounted) {
      setState(() {
        _messages.addAll([
          ChatMessage('CosmicFan', 'First! 🎉'),
          ChatMessage('GamerPro', 'Let\'s gooo!'),
          ChatMessage('StreamLover', 'Great stream today!'),
          ChatMessage('LunarViewer', '❤️❤️❤️'),
        ]);
      });
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    
    final messageText = _chatController.text.trim();
    
    // Optimistic add
    setState(() {
      _messages.add(ChatMessage('You', messageText));
      _chatController.clear();
    });
    
    // Send to API
    try {
      final streamId = int.tryParse(widget.streamer.id.toString());
      if (streamId != null) {
        await ApiService.sendChatMessage(streamId, messageText);
      }
    } catch (e) {
      print('Failed to send message: $e');
      // Keep the message in UI even if API fails
    }
  }

  void _toggleLike() {
    setState(() => MockDataService.toggleLike(widget.streamer.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.streamer.isLiked ? '❤️ Liked!' : 'Unliked'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleFollow() async {
    final wasFollowed = widget.streamer.isFollowed;
    
    // Optimistic update via mock service
    setState(() => MockDataService.toggleFollow(widget.streamer.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.streamer.isFollowed ? '✅ Following ${widget.streamer.displayName}' : 'Unfollowed'),
        duration: const Duration(seconds: 1),
      ),
    );
    
    // Sync with API
    try {
      final streamerId = int.tryParse(widget.streamer.id.toString());
      if (streamerId != null) {
        final success = widget.streamer.isFollowed
            ? await ApiService.followUser(streamerId)
            : await ApiService.unfollowUser(streamerId);
        
        if (!success && mounted) {
          // Rollback on failure
          setState(() => MockDataService.toggleFollow(widget.streamer.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update follow'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Follow error: $e');
    }
  }

  void _shareStream() {
    // Share.share('Check out ${widget.streamer.displayName} streaming ${widget.streamer.game} on Arcade Lunar! 🎮');
  }

  void _sendGift(MockGift gift) {
    final success = MockDataService.sendGift(widget.streamer.id, gift);
    setState(() => _showGiftPanel = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '${gift.emoji} ${gift.name} sent! (-${gift.cost} coins)' : 'Not enough coins!'),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video area (mock gradient)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary.withOpacity(0.3), AppColors.secondary.withOpacity(0.3)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.live_tv_rounded, size: 80, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('${widget.streamer.displayName}\'s Stream', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(widget.streamer.title, style: TextStyle(color: Colors.white.withOpacity(0.5)), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      ),
                      child: Center(child: Text(widget.streamer.avatarInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.streamer.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(widget.streamer.game, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(_formatViewers(widget.streamer.viewers), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.streamer.isFollowed ? Colors.grey : AppColors.primary,
                        minimumSize: const Size(70, 32),
                      ),
                      child: Text(widget.streamer.isFollowed ? 'Following' : 'Follow', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

            // Chat overlay (right side)
            Positioned(
              right: 0,
              top: 80,
              bottom: 120,
              width: 280,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(text: '${msg.username}: ', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                  TextSpan(text: msg.message, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Say something...',
                              hintStyle: TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white10,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: AppColors.primary, size: 20),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom action bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: widget.streamer.isLiked ? Icons.favorite : Icons.favorite_border,
                      label: 'Like',
                      color: widget.streamer.isLiked ? Colors.red : Colors.white,
                      onTap: _toggleLike,
                    ),
                    _buildActionButton(
                      icon: Icons.card_giftcard,
                      label: 'Gift',
                      color: Colors.amber,
                      onTap: () => setState(() => _showGiftPanel = !_showGiftPanel),
                    ),
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      color: Colors.white,
                      onTap: _shareStream,
                    ),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      color: Colors.white,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Gift panel
            if (_showGiftPanel)
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Send a Gift', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('💰 ${MockDataService.userCoins} coins', style: TextStyle(color: Colors.amber)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: MockDataService.gifts.map((gift) => GestureDetector(
                          onTap: () => _sendGift(gift),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(gift.emoji, style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(height: 4),
                              Text('${gift.cost}', style: TextStyle(color: Colors.amber, fontSize: 10)),
                            ],
                          ),
                        )).toList(),
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

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }

  String _formatViewers(int viewers) {
    if (viewers >= 1000) {
      return '${(viewers / 1000).toStringAsFixed(1)}K';
    }
    return viewers.toString();
  }
}

class ChatMessage {
  final String username;
  final String message;
  ChatMessage(this.username, this.message);
}
