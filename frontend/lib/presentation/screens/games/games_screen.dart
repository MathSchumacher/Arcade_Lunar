import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utils/content_moderator.dart';
import '../../../data/services/auth_service.dart';

/// Games/Browse Screen - Twitch-style Browse page
/// Includes Top Categories (horizontal) and Live Channels (vertical)
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  final _searchController = TextEditingController();
  bool _isAdminAccount = false;
  
  // Categories and streams - only populated for admin
  List<GameCategory> _categories = [];
  List<LiveStream> _liveStreams = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      final isAdmin = user['email'] == 'admin@arcade.lunar';
      setState(() {
        _isAdminAccount = isAdmin;
        if (isAdmin) {
          // Only load mock data for admin account
          _categories = _mockCategories;
          _liveStreams = _mockStreams;
        } else {
          _categories = [];
          _liveStreams = [];
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // AppBar / Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Browser',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                  ],
                ),
              ),
            ),
            
            // Top Categories Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Top Categorias',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Ver tudo',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories Horizontal List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140, // Reduced height for mobile polish
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Live Channels Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Canais Recomendados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Live Channels List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStreamCard(_liveStreams[index]),
                childCount: _liveStreams.length,
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 80)), // Bottom nav padding
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          hintText: 'Buscar jogos, canais, tags...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 2),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(GameCategory category) {
    // Smaller, more robust card for categories
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 90,
          height: 120, // 3:4 aspect ratio
          decoration: BoxDecoration(
            color: category.color,
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [category.color, category.color.withOpacity(0.6)],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  _getIconForCategory(category.slug),
                  color: Colors.white.withOpacity(0.3),
                  size: 40,
                ),
              ),
              // Name overlay
              Positioned(
                bottom: 8,
                left: 4,
                right: 4,
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreamCard(LiveStream stream) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface.withOpacity(0.3), // Subtle separation
      child: InkWell(
        onTap: () {
          // TODO: Navigate to stream
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 80, // 16:9 ratio approx
                    decoration: BoxDecoration(
                      color: stream.thumbnailColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white.withOpacity(0.2), size: 40),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatNumber(stream.viewers),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: stream.avatarColor,
                          child: Text(stream.streamer[0], style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stream.streamer,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stream.title,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGameName(stream.gameSlug),
                      style: TextStyle(color: AppColors.primary, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    // Tags
                    Wrap(
                      spacing: 4,
                      children: stream.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helpers
  String _getGameName(String slug) {
    final cats = _categories.isNotEmpty ? _categories : _mockCategories;
    final cat = cats.firstWhere((c) => c.slug == slug, orElse: () => cats[0]);
    return cat.name;
  }

  IconData _getIconForCategory(String slug) {
    if (slug == 'just-chatting') return Icons.chat;
    if (slug == 'minecraft') return Icons.grid_view;
    if (slug == 'valorant' || slug == 'cs2') return Icons.gps_fixed;
    return Icons.gamepad;
  }
}

class GameCategory {
  final String name;
  final String slug;
  final int viewers;
  final Color color;

  GameCategory({required this.name, required this.slug, required this.viewers, required this.color});
}

class LiveStream {
  final String title;
  final String streamer;
  final String gameSlug;
  final int viewers;
  final List<String> tags;
  final Color thumbnailColor;
  final Color avatarColor;

  LiveStream({
    required this.title,
    required this.streamer,
    required this.gameSlug,
    required this.viewers,
    required this.tags,
    required this.thumbnailColor,
    required this.avatarColor,
  });
}

// Mock data - only loaded for admin@arcade.lunar account
final List<GameCategory> _mockCategories = [
  GameCategory(name: 'Just Chatting', slug: 'just-chatting', viewers: 125000, color: const Color(0xFF9B5DE5)),
  GameCategory(name: 'Valorant', slug: 'valorant', viewers: 89000, color: const Color(0xFFFF4655)),
  GameCategory(name: 'LoL', slug: 'league-of-legends', viewers: 75000, color: const Color(0xFF0AC8B9)),
  GameCategory(name: 'Minecraft', slug: 'minecraft', viewers: 62000, color: const Color(0xFF62B47A)),
  GameCategory(name: 'GTA V', slug: 'gta-v', viewers: 58000, color: const Color(0xFFF5A623)),
  GameCategory(name: 'Fortnite', slug: 'fortnite', viewers: 52000, color: const Color(0xFF00D4FF)),
  GameCategory(name: 'CS2', slug: 'cs2', viewers: 48000, color: const Color(0xFFDE9B35)),
  GameCategory(name: 'Apex', slug: 'apex-legends', viewers: 42000, color: const Color(0xFFCD3333)),
  GameCategory(name: 'DOTA 2', slug: 'dota-2', viewers: 38000, color: const Color(0xFFD32929)),
  GameCategory(name: 'WoW', slug: 'wow', viewers: 35000, color: const Color(0xFFF9AB00)),
];

final List<LiveStream> _mockStreams = [
  LiveStream(
    title: 'RANKED | RUMO AO RADIANTE | !loja',
    streamer: 'Coreano',
    gameSlug: 'valorant',
    viewers: 15420,
    tags: ['FPS', 'Português', 'Tryhard'],
    thumbnailColor: Colors.red.shade900,
    avatarColor: Colors.white,
  ),
  LiveStream(
    title: 'Conversa fiada e reagindo a vídeos',
    streamer: 'Alanzoka',
    gameSlug: 'just-chatting',
    viewers: 22300,
    tags: ['Humor', 'React'],
    thumbnailColor: Colors.purple.shade900,
    avatarColor: Colors.amber,
  ),
  LiveStream(
    title: 'CBLOL - PAIN vs LOUD (MD5)',
    streamer: 'CBLOL',
    gameSlug: 'league-of-legends',
    viewers: 98500,
    tags: ['Esports', 'Campeonato'],
    thumbnailColor: Colors.blue.shade900,
    avatarColor: Colors.cyan,
  ),
  LiveStream(
    title: 'Construindo a nova base - Hardcore #54',
    streamer: 'Viniccius13',
    gameSlug: 'minecraft',
    viewers: 12100,
    tags: ['Survival', 'Redstone'],
    thumbnailColor: Colors.green.shade900,
    avatarColor: Colors.green,
  ),
  LiveStream(
    title: 'RP da madrugada - Cidade Alta',
    streamer: 'PaulinhoLoko',
    gameSlug: 'gta-v',
    viewers: 45200,
    tags: ['RP', 'Roleplay', 'Engraçado'],
    thumbnailColor: Colors.orange.shade900,
    avatarColor: Colors.orange,
  ),
  LiveStream(
    title: 'Treino de Aim - Aquecendo',
    streamer: 'Fallen',
    gameSlug: 'cs2',
    viewers: 18900,
    tags: ['Pro', 'CS2'],
    thumbnailColor: Colors.brown.shade900,
    avatarColor: Colors.grey,
  ),
];
