import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/models/friend_model.dart';
import '../../data/models/trending_model.dart';
import '../../data/models/featured_model.dart';
import '../../data/models/post_model.dart';
import '../../data/services/api_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/section_header.dart';
import '../widgets/friend_item.dart';
import '../widgets/trending_card.dart';
import '../widgets/post_card.dart';
import '../widgets/countdown_timer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final results = await Future.wait([
      _apiService.getCurrentUser(),
      _apiService.getFriends(),
      _apiService.getFeaturedEvent(),
      _apiService.getTrending(),
      _apiService.getFeed(),
    ]);

    return {
      'user': results[0] as User,
      'friends': results[1] as List<Friend>,
      'featured': results[2] as FeaturedEvent,
      'trending': results[3] as List<Trending>,
      'feed': results[4] as List<Post>,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No data found'));
            }

            final data = snapshot.data!;
            final user = data['user'] as User;
            final friends = data['friends'] as List<Friend>;
            final featured = data['featured'] as FeaturedEvent;
            final trending = data['trending'] as List<Trending>;
            final feed = data['feed'] as List<Post>;

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _dataFuture = _fetchData();
                });
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context, user),

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

                    // Featured Banner
                    _buildFeaturedBanner(context, featured),

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
                        child: Row(
                          children: [
                             Icon(Icons.bar_chart, size: 14, color: AppColors.textSecondary),
                             SizedBox(width: 4),
                             Text("Last Watched", style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                          ],
                        )
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
                    // Feed Items
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user.avatar,
            size: 48,
            isOnline: true,
            showBorder: true,
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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                            color: AppColors.secondary, // Just to match design somewhat
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
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                minimumSize: Size(0, 32)
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
}
