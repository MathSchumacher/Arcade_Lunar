import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/email_verification_screen.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Settings Screen - Mobile-first design
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  final ImagePicker _picker = ImagePicker();
  
  // User data
  Map<String, dynamic>? _userData;
  bool _emailVerified = true; // Default to true to hide verification section
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _userData = user;
        _emailVerified = user['emailVerified'] ?? user['email_verified'] ?? true;
      });
    }
  }

  String _getInitial() {
    final name = _userData?['username'] ?? _userData?['email']?.split('@')[0] ?? 'U';
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
            _buildSection(
              title: 'Profile Photo',
              icon: Icons.account_circle_rounded,
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                      image: _userData?['avatarUrl'] != null ? DecorationImage(
                        image: NetworkImage(_userData!['avatarUrl']),
                        fit: BoxFit.cover,
                      ) : null,
                    ),
                    child: _userData?['avatarUrl'] == null ? Center(
                      child: Text(
                        _getInitial(),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Change Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Upload a new profile picture', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                    onPressed: _changePhoto,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Info Section
            _buildSection(
              title: 'Account Info',
              icon: Icons.person_rounded,
              child: Column(
                children: [
                  _buildInfoRow(
                    label: 'Username',
                    value: '@${_userData?['username'] ?? _userData?['email']?.split('@')[0] ?? 'user'}',
                    isEditable: true,
                    onEdit: () => _showEditDialog('Username', '@${_userData?['username'] ?? 'user'}'),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(
                    label: 'Email',
                    value: _userData?['email'] ?? 'Not set',
                    isEditable: true,
                    onEdit: () => _showEditDialog('Email', _userData?['email'] ?? ''),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(
                    label: 'Phone',
                    value: _userData?['phone'] ?? 'Not set',
                    isEditable: true,
                    onEdit: () => _showEditDialog('Phone', _userData?['phone'] ?? ''),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(
                    label: 'Password',
                    value: '••••••••',
                    isEditable: true,
                    onEdit: _changePassword,
                  ),
                ],
              ),
            ),

            // Email Verification Section (only show if not verified)
            if (!_emailVerified && _userData?['email'] != null) ...[
              const SizedBox(height: 24),
              _buildSection(
                title: 'Email Verification',
                icon: Icons.mark_email_unread_rounded,
                iconColor: Colors.orange,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Seu email ainda não foi verificado. Verifique para proteger sua conta.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _startEmailVerification,
                        icon: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.verified_user, size: 18),
                        label: Text(_isLoading ? 'Enviando...' : 'Verificar Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Personal Info Section (Non-editable)
            _buildSection(
              title: 'Personal Info',
              icon: Icons.badge_rounded,
              child: Column(
                children: [
                  _buildInfoRow(
                    label: 'Full Name',
                    value: _userData?['fullName'] ?? _userData?['username'] ?? 'Not set',
                    isEditable: false,
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow(
                    label: 'Date of Birth',
                    value: _userData?['dateOfBirth'] ?? 'Not set',
                    isEditable: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preferences Section
            _buildSection(
              title: 'Preferences',
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  _buildToggleRow(
                    label: 'Push Notifications',
                    description: 'Receive alerts for new followers and streams',
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildToggleRow(
                    label: 'Dark Mode',
                    description: 'Use dark theme across the app',
                    value: _darkMode,
                    onChanged: (value) => setState(() => _darkMode = value),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Danger Zone
            _buildSection(
              title: 'Danger Zone',
              icon: Icons.warning_rounded,
              iconColor: Colors.red,
              child: Column(
                children: [
                  _buildDangerButton(
                    label: 'Sign Out',
                    icon: Icons.logout_rounded,
                    onTap: _signOut,
                  ),
                  const SizedBox(height: 12),
                  _buildDangerButton(
                    label: 'Delete Account',
                    icon: Icons.delete_forever_rounded,
                    onTap: _deleteAccount,
                    isDestructive: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // App Version
            Center(
              child: Text(
                'Arcade Lunar v1.0.0',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isEditable,
    VoidCallback? onEdit,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (isEditable)
          IconButton(
            icon: Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
            onPressed: onEdit,
          )
        else
          Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 18),
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(description, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildDangerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: isDestructive ? Colors.red.withOpacity(0.15) : Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDestructive ? Colors.red : Colors.white70, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: isDestructive ? Colors.red : Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startEmailVerification() async {
    if (_userData == null || _userData!['email'] == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final response = await AuthService.requestEmailVerification();
      
      if (!mounted) return;
      
      if (response['success'] == true) {
        // Navigate to email verification screen
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              email: _userData!['email'],
              userId: _userData!['id'] ?? 0,
            ),
          ),
        );
        
        if (result == true && mounted) {
          // Email verified successfully
          setState(() => _emailVerified = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Email verificado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh user data
          _loadUserData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Alterar foto de perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Galeria', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 85,
                  );
                  if (image != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Foto atualizada!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Tirar Foto', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 85,
                  );
                  if (image != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Foto capturada!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String field, String currentValue) {
    // Special handling for Phone field with CountryCodePicker
    if (field == 'Phone') {
      _showPhoneEditDialog(currentValue);
      return;
    }
    
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $field', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$field updated!')),
              );
            },
            child: Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showPhoneEditDialog(String currentPhone) {
    String countryCode = '+55'; // Default
    final phoneController = TextEditingController(text: currentPhone.split(' ').last);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Phone', style: TextStyle(color: Colors.white)),
        content: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Country Code Picker
              CountryCodePicker(
                onChanged: (country) => countryCode = country.dialCode!,
                initialSelection: 'BR',
                favorite: const ['+55', 'BR', '+1', 'US'],
                showCountryOnly: false,
                showOnlyCountryWhenClosed: false,
                alignLeft: false,
                backgroundColor: AppColors.surface,
                dialogBackgroundColor: AppColors.surface,
                textStyle: const TextStyle(color: Colors.white, fontSize: 14),
                dialogTextStyle: const TextStyle(color: Colors.white),
                searchStyle: const TextStyle(color: Colors.white),
                searchDecoration: InputDecoration(
                  hintText: 'Search country',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.surface.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.primary.withOpacity(0.2)),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone updated!')),
              );
            },
            child: Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed!')),
              );
            },
            child: Text('Change', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _signOut() {
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
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.red)),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: Implement account deletion
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
