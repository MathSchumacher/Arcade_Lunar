import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utils/content_moderator.dart';

/// Edit Profile Screen - Mobile-first design
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController(text: 'CosmicGamer');
  final _bioController = TextEditingController(text: '🎮 Passionate gamer | Valorant & LoL streamer');
  
  final List<Map<String, String>> _links = [
    {'label': 'Twitter', 'url': 'twitter.com/cosmicgamer'},
    {'label': 'Discord', 'url': 'discord.gg/cosmic'},
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMediaSection(),
            const SizedBox(height: 56),
            _buildTextField(
              label: 'Display Name',
              controller: _displayNameController,
              maxLength: 25,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Bio',
              controller: _bioController,
              maxLength: 160,
              maxLines: 3,
              hint: 'Tell viewers about yourself...',
            ),
            const SizedBox(height: 32),
            _buildLinksSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: _changeBanner,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          left: 20,
          child: GestureDetector(
            onTap: _changeAvatar,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 4),
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Text('C', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.background, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int? maxLength,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (maxLength != null)
              Text('${controller.text.length}/$maxLength', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Custom Links', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _addLink,
              icon: Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
              label: Text('Add Link', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: _links.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('No links added yet', style: TextStyle(color: AppColors.textSecondary))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _links.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                  itemBuilder: (context, index) => _buildLinkItem(index),
                ),
        ),
      ],
    );
  }

  Widget _buildLinkItem(int index) {
    final link = _links[index];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
      ),
      title: Text(link['label']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(link['url']!, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 20),
        onPressed: () => _removeLink(index),
      ),
    );
  }

  void _changeBanner() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select banner image...')));
  }

  void _changeAvatar() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select avatar image...')));
  }

  void _addLink() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) => _AddLinkSheet(
        onAdd: (label, url) => setState(() => _links.add({'label': label, 'url': url})),
      ),
    );
  }

  void _removeLink(int index) => setState(() => _links.removeAt(index));

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Profile saved!'), backgroundColor: AppColors.primary));
    Navigator.pop(context);
  }
}

/// Bottom sheet for adding a new link with 18+ content validation
class _AddLinkSheet extends StatefulWidget {
  final Function(String label, String url) onAdd;
  const _AddLinkSheet({required this.onAdd});

  @override
  State<_AddLinkSheet> createState() => _AddLinkSheetState();
}

class _AddLinkSheetState extends State<_AddLinkSheet> {
  final _labelController = TextEditingController();
  final _urlController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _labelController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _validateAndAdd() {
    final label = _labelController.text.trim();
    final url = _urlController.text.trim();

    if (label.isEmpty) {
      setState(() => _errorMessage = 'Please enter a label');
      return;
    }
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please enter a URL');
      return;
    }

    // Check for 18+ content
    final blockReason = LinkModerator.checkLink(url);
    if (blockReason != null) {
      setState(() => _errorMessage = blockReason);
      return;
    }

    widget.onAdd(label, url);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Add Link', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade300, fontSize: 13))),
                ],
              ),
            ),

          TextField(
            controller: _labelController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Label',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'URL',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (_) => setState(() => _errorMessage = null),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _validateAndAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
