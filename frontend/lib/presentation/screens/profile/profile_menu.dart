import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../auth/login_screen.dart';
import 'view_profile_screen.dart';
import 'edit_profile_screen.dart';
import 'stream_config_screen.dart';
import 'settings_screen.dart';

/// Profile Menu - Mobile bottom sheet style
class ProfileMenu extends StatefulWidget {
  final VoidCallback? onClose;

  const ProfileMenu({super.key, this.onClose});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  String _username = 'Loading...';
  String _avatarUrl = '';
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _username = user['username'] ?? user['email']?.split('@')[0] ?? 'User';
        _displayName = _username;
        _avatarUrl = user['avatarUrl'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width bottom sheet
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16)],
                    image: _avatarUrl.isNotEmpty ? DecorationImage(
                      image: NetworkImage(_avatarUrl),
                      fit: BoxFit.cover,
                    ) : null,
                  ),
                  child: _avatarUrl.isEmpty ? Center(
                    child: Text(_username.isNotEmpty ? _username[0].toUpperCase() : 'U', 
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ) : null,
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('@${_username.toLowerCase()}', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    ],
                  ),
                ),
                // Online indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Online', style: TextStyle(color: Colors.green.shade300, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Menu Items with larger padding
          const SizedBox(height: 8),
          _MenuItem(icon: Icons.person_outline_rounded, label: 'View Profile', onTap: () => _navigateTo(context, const ViewProfileScreen())),
          _MenuItem(icon: Icons.edit_outlined, label: 'Edit Profile', onTap: () => _navigateTo(context, const EditProfileScreen())),
          _MenuItem(icon: Icons.videocam_outlined, label: 'Stream Settings', onTap: () => _navigateTo(context, const StreamConfigScreen())),
          _MenuItem(icon: Icons.settings_outlined, label: 'Account Settings', onTap: () => _navigateTo(context, const SettingsScreen())),
          
          const Divider(height: 1, color: Colors.white10, indent: 24, endIndent: 24),
          
          _MenuItem(icon: Icons.logout_rounded, label: 'Sign Out', isDestructive: true, onTap: () => _handleLogout(context)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _handleLogout(BuildContext context) {
    Navigator.pop(context); // Close bottom sheet
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Actually clear session
              await AuthService.logout();
              await AuthService.clearSession();
              // Navigate to login and remove all routes
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}


class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : AppColors.textSecondary, size: 26),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Show profile menu as a bottom sheet (mobile-friendly)
void showProfileMenu(BuildContext context, {Offset? position}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const ProfileMenu(),
  );
}
