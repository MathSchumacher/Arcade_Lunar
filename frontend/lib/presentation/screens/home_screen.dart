import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/models/friend_model.dart';
import '../../data/models/trending_model.dart';
import '../../data/models/featured_model.dart';
import '../../data/models/post_model.dart';
import '../../data/services/mock_data_service.dart';
import '../../data/services/auth_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/section_header.dart';
import '../widgets/friend_item.dart';
import '../widgets/trending_card.dart';
import '../widgets/post_card.dart';
import '../widgets/countdown_timer.dart';
import 'profile/profile_menu.dart';
import 'live/stream_viewer_screen.dart';
import 'notifications/notifications_screen.dart';
import 'live/lives_section_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Animation controllers for header buttons
  late AnimationController _searchAnimController;
  late AnimationController _bellAnimController;
  late Animation<double> _searchScaleAnim;
  late Animation<double> _bellScaleAnim;
  
  // Notification count for badge
  int _notificationCount = 0;
  
  // Track if this is the admin mock account
  bool _isAdminAccount = false;
  
  // User data - loaded from session or mock
  User user = User(
    id: 'loading',
    username: 'Loading...',
    displayName: 'Hi, ...',
    avatar: 'https://ui-avatars.com/api/?name=U&background=6C63FF&color=fff&size=150',
    level: 1,
    coins: 0,
    isOnline: true,
    status: 'Loading...',
  );
  List<Friend> friends = [];
  FeaturedEvent? featured;
  List<Trending> trending = [];
  List<Post> feed = [];
  
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Initialize header button animations
    _searchAnimController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _bellAnimController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _searchScaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _searchAnimController, curve: Curves.easeInOut),
    );
    _bellScaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _bellAnimController, curve: Curves.easeInOut),
    );
  }


  @override
  void dispose() {
    _searchAnimController.dispose();
    _bellAnimController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    // Try to load real user from session
    try {
      final sessionUser = await AuthService.getUser();
      
      if (sessionUser != null && mounted) {
        // Check if this is the admin mock account
        final isAdmin = sessionUser['email'] == 'admin@arcade.lunar';
        
        setState(() {
          _isAdminAccount = isAdmin;
          _notificationCount = isAdmin ? 3 : 0;
          
          user = User(
            id: sessionUser['id']?.toString() ?? 'user_001',
            username: sessionUser['username'] ?? sessionUser['email']?.split('@')[0] ?? 'User',
            displayName: 'Hi, ${sessionUser['username'] ?? sessionUser['email']?.split('@')[0] ?? 'User'}',
            avatar: sessionUser['avatarUrl'] ?? 'https://ui-avatars.com/api/?name=${sessionUser['username'] ?? 'U'}&background=6C63FF&color=fff&size=150',
            level: isAdmin ? 42 : 1,
            coins: isAdmin ? MockDataService.userCoins : 0,
            isOnline: true,
            status: isAdmin ? '🎮 Gaming' : '🌟 New Member',
          );
        });
        
        // Load content data AFTER we know if it's admin
        _loadContentData();
        return;
      }
    } catch (e) {
      debugPrint('Error loading user session: $e');
    }
    
    // Fallback: No session, use guest data (no mock data)
    if (mounted) {
      setState(() {
        _isAdminAccount = false;
        _notificationCount = 0;
        user = User(
          id: 'guest',
          username: 'Guest',
          displayName: 'Hi, Guest',
          avatar: 'https://ui-avatars.com/api/?name=Guest&background=6C63FF&color=fff&size=150',
          level: 1,
          coins: 0,
          isOnline: true,
          status: '👋 Welcome!',
        );
      });
      _loadContentData();
    }
  }

  void _loadContentData() {
    // ONLY load mock data for admin@arcade.lunar account
    // All other accounts see empty content
    
    if (_isAdminAccount) {
      // Admin account gets mock demo data
      friends = [
        Friend(id: 'f1', username: 'Alex', avatar: 'https://picsum.photos/seed/alex/150/150', isOnline: true, status: 'Playing Valorant', game: 'Valorant'),
        Friend(id: 'f2', username: 'Luna', avatar: 'https://picsum.photos/seed/luna/150/150', isOnline: true, status: 'Streaming', game: 'Just Chatting'),
        Friend(id: 'f3', username: 'Max', avatar: 'https://picsum.photos/seed/max/150/150', isOnline: true, status: 'In Queue', game: 'League of Legends'),
        Friend(id: 'f4', username: 'Ryan', avatar: 'https://picsum.photos/seed/ryan/150/150', isOnline: true, status: 'In Match', game: 'CS2'),
        Friend(id: 'f5', username: 'Sophie', avatar: 'https://picsum.photos/seed/sophie/150/150', isOnline: true, status: 'Watching Stream', game: null),
        Friend(id: 'f6', username: 'Zara', avatar: 'https://picsum.photos/seed/zara/150/150', isOnline: false, status: 'Offline', game: null),
      ];

      featured = FeaturedEvent(
        id: 'event_001',
        title: 'Cosmic Cup Finals',
        subtitle: 'Win exclusive badges & XP boost',
        backgroundImage: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&q=80',
        endTime: DateTime.now().add(const Duration(hours: 2, minutes: 26)),
        prizes: ['Exclusive Badge', '500 XP', 'Cosmic Skin'],
      );

      trending = [
        Trending(id: 't1', title: 'FPS Tournament Finals', streamer: 'ProGamer', thumbnail: 'https://images.unsplash.com/photo-1542751110-97427bbecf20?w=400&q=80', viewers: 15420, isLive: true, game: 'Valorant', duration: '2:34:15'),
        Trending(id: 't2', title: 'Speedrun Challenge', streamer: 'FastHands', thumbnail: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=400&q=80', viewers: 12300, isLive: true, game: 'Elden Ring', duration: '45:20'),
        Trending(id: 't3', title: 'Just Chatting & Chill', streamer: 'ChillVibes', thumbnail: 'https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=400&q=80', viewers: 8750, isLive: true, game: 'Just Chatting', duration: '1:15:42'),
        Trending(id: 't4', title: 'Ranked Grind', streamer: 'TryHard', thumbnail: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&q=80', viewers: 6200, isLive: false, game: 'League of Legends', duration: '3:20:00'),
      ];

      feed = [
        Post(
          id: 'p1',
          author: PostAuthor(id: 'u1', username: 'Shadow Riser', avatar: 'https://picsum.photos/seed/shadow/150/150', isVerified: false, badge: '1 Lugar'),
          content: 'The energy at this tournament was absolutely unreal! 🔥💪 Can\'t wait for the next season. #legends',
          images: [
            'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&q=80',
            'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=600&q=80',
            'https://images.unsplash.com/photo-1560253023-3ec5d502959f?w=600&q=80',
            'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=600&q=80',
          ],
          likes: 2400,
          comments: 227,
          shares: 45,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isLiked: false,
        ),
        Post(
          id: 'p2',
          author: PostAuthor(id: 'u2', username: 'PixelRunner', avatar: 'https://picsum.photos/seed/pixel/150/150', isVerified: false, badge: null),
          content: 'Finally hit GM after 500 hours! The grind was real 💎',
          images: [],
          likes: 892,
          comments: 64,
          shares: 12,
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          isLiked: true,
        ),
        Post(
          id: 'p3',
          author: PostAuthor(id: 'u3', username: 'Light Yagami', avatar: 'https://picsum.photos/seed/light/150/150', isVerified: false, badge: 'Streamer'),
          content: 'Late night grind with the new setup 🖥️',
          images: [
            'https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=600&q=80',
            'https://images.unsplash.com/photo-1598550476439-6847785fcea6?w=600&q=80',
          ],
          likes: 1567,
          comments: 89,
          shares: 23,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          isLiked: false,
        ),
      ];
    } else {
      // Non-admin accounts: EMPTY content (no mock data)
      friends = [];
      featured = null;
      trending = [];
      feed = [];
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show favorite streams for admin account
    final favoriteStreams = _isAdminAccount ? MockDataService.favoriteLiveStreamers : <MockStreamer>[];
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              _loadUserData();
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context, user),

                  // Favorites Section (if user follows any live streamers)
                  if (favoriteStreams.isNotEmpty) ...[
                    SectionHeader(
                      title: '❤️ FAVORITE LIVES',
                      onSeeAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LivesSectionScreen()),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text('${favoriteStreams.length} LIVE', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: favoriteStreams.length,
                        itemBuilder: (context, index) => _buildFavoriteStreamCard(favoriteStreams[index]),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Friends Online
                  SectionHeader(
                    title: 'FRIENDS ONLINE',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${friends.where((f) => f.isOnline).length} ONLINE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        return FriendItem(friend: friends[index]);
                      },
                    ),
                  ),

                  // Featured Banner (only show if available)
                  if (featured != null)
                    _buildFeaturedBanner(context, featured!),

                  // Trending Section
                  SectionHeader(
                    title: 'Trending',
                    onSeeAll: () {},
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bar_chart, size: 14, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text("Last Watched", style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: trending.length,
                      itemBuilder: (context, index) {
                        return TrendingCard(item: trending[index]);
                      },
                    ),
                  ),

                  // Social Feed
                  ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: feed.length,
                    itemBuilder: (context, index) {
                      return PostCard(post: feed[index]);
                    },
                  ),
                  
                  const SizedBox(height: 80), // Bottom padding for nav bar
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showProfileMenu(context, position: const Offset(0, 80)),
            child: UserAvatar(
              imageUrl: user.avatar,
              size: 48,
              isOnline: true,
              showBorder: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '+ 2 Friends live',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.success,
                      ),
                ),
              ],
            ),
          ),
          // Animated Search Button
          ScaleTransition(
            scale: _searchScaleAnim,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () {
                  _searchAnimController.forward().then((_) {
                    _searchAnimController.reverse();
                    _openSearch();
                  });
                },
                icon: const Icon(Icons.search, color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Animated Notification Bell
          ScaleTransition(
            scale: _bellScaleAnim,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      _bellAnimController.forward().then((_) {
                        _bellAnimController.reverse();
                        _openNotifications();
                      });
                    },
                    icon: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
                  ),
                ),
                if (_notificationCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _notificationCount > 9 ? '9+' : _notificationCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search users, streams, games...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (query) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching: $query')),
                );
              },
            ),
            const SizedBox(height: 20),
            // Recent Searches
            const Row(
              children: [
                Icon(Icons.history, color: AppColors.textSecondary, size: 18),
                SizedBox(width: 8),
                Text('Recent', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['Valorant', 'NinjaLunar', 'League'].map((s) => Chip(
                label: Text(s, style: const TextStyle(color: Colors.white)),
                backgroundColor: AppColors.primary.withOpacity(0.3),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {},
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _openNotifications() {
    setState(() => _notificationCount = 0); // Clear badge
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  Widget _buildFeaturedBanner(BuildContext context, FeaturedEvent event) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: CachedNetworkImageProvider(event.backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.9),
                  AppColors.background.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'EXCLUSIVE EVENT',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Text(
                      'Ending soon',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        CountdownTimer(
                          endTime: event.endTime,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontFamily: 'monospace',
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 8),
                         ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                minimumSize: const Size(0, 32)
                              ),
                              child: const Text('JOIN NOW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a favorite stream card for the favorites section
  Widget _buildFavoriteStreamCard(MockStreamer streamer) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StreamViewerScreen(streamer: streamer)),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with live badge
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.6), AppColors.secondary.withOpacity(0.6)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.7), size: 36),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(_formatViewers(streamer.viewers), style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Streamer info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                    ),
                    child: Center(child: Text(streamer.avatarInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(streamer.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                        Text(streamer.game, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

