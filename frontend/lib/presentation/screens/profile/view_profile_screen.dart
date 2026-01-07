import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'edit_profile_screen.dart';

/// View Profile Screen - Simple mobile-first layout without SliverAppBar
class ViewProfileScreen extends StatelessWidget {
  const ViewProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock user data
    final links = [
      {'label': 'Twitter', 'url': 'twitter.com/cosmicgamer'},
      {'label': 'Discord', 'url': 'discord.gg/cosmic'},
      {'label': 'Donate', 'url': 'streamelements.com/cosmic'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Banner Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner Image/Gradient
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                  ),
                  child: CustomPaint(painter: _GridPatternPainter()),
                ),

                // Back & Share buttons
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildIconButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                        _buildIconButton(Icons.share_rounded, () {}),
                      ],
                    ),
                  ),
                ),

                // Avatar positioned at bottom of banner
                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildAvatar()),
                ),
              ],
            ),

            // Space for avatar overlap
            const SizedBox(height: 60),

            // User Info
            _buildUserInfo(context, links),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 4),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20),
        ],
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
      ),
      child: Stack(
        children: [
          const Center(
            child: Text('C', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, List<Map<String, String>> links) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Name & Verification
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('CosmicGamer', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('@cosmicgamer', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),

          const SizedBox(height: 20),

          // Stats Row
          _buildStatsRow(),

          const SizedBox(height: 20),

          // Bio
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  '🎮 Passionate gamer | Valorant & LoL streamer | Join the lunar community! 🌙✨',
                  style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Links - Clickable
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Links', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...links.map((link) => _buildLinkItem(link['label']!, link['url']!)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('Followers', '12.5K'),
          Container(width: 1, height: 30, color: Colors.white12),
          _buildStat('Following', '256'),
          Container(width: 1, height: 30, color: Colors.white12),
          _buildStat('Streams', '89'),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildLinkItem(String label, String url) {
    return InkWell(
      onTap: () {
        // TODO: Open URL
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.link_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(url, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}

// Grid pattern for banner
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1;

    const spacing = 25.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
