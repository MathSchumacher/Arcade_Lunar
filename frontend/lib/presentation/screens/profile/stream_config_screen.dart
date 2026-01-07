import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

/// Stream Config Screen - Mobile-first design
class StreamConfigScreen extends StatefulWidget {
  const StreamConfigScreen({super.key});

  @override
  State<StreamConfigScreen> createState() => _StreamConfigScreenState();
}

class _StreamConfigScreenState extends State<StreamConfigScreen> {
  bool _showStreamKey = false;
  double _micVolume = 0.75;
  bool _screenShareEnabled = true;
  String _selectedMic = 'Default Microphone';
  final String _streamKey = 'live_abc123xyz789_secret';

  final List<String> _mics = [
    'Default Microphone',
    'External USB Mic',
    'Headset Microphone',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Stream Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
            // Stream Key Section
            _buildSection(
              title: 'Stream Key',
              icon: Icons.key_rounded,
              child: Column(
                children: [
                  // Key Display
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _showStreamKey ? _streamKey : '••••••••••••••••••••',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: _showStreamKey ? 'monospace' : null,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showStreamKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _showStreamKey = !_showStreamKey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.copy_rounded,
                          label: 'Copy',
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _streamKey));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Stream key copied!')),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.refresh_rounded,
                          label: 'Regenerate',
                          isDestructive: true,
                          onTap: _regenerateStreamKey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Audio Settings Section
            _buildSection(
              title: 'Audio',
              icon: Icons.mic_rounded,
              child: Column(
                children: [
                  // Microphone Selector
                  _buildDropdown(
                    label: 'Microphone',
                    value: _selectedMic,
                    items: _mics,
                    onChanged: (value) => setState(() => _selectedMic = value!),
                  ),
                  const SizedBox(height: 20),
                  // Volume Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Volume', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text('${(_micVolume * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                          overlayColor: AppColors.primary.withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _micVolume,
                          onChanged: (value) => setState(() => _micVolume = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Test Mic Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testMicrophone,
                      icon: Icon(Icons.record_voice_over_rounded, color: AppColors.primary),
                      label: Text('Test Microphone', style: TextStyle(color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Screen Share Section
            _buildSection(
              title: 'Screen Share',
              icon: Icons.screen_share_rounded,
              child: _buildToggleRow(
                label: 'Enable Screen Share',
                description: 'Allow sharing your screen during streams',
                value: _screenShareEnabled,
                onChanged: (value) => setState(() => _screenShareEnabled = value),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: isDestructive ? Colors.red.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDestructive ? Colors.red : AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isDestructive ? Colors.red : AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              icon: Icon(Icons.expand_more_rounded, color: AppColors.textSecondary),
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
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

  void _regenerateStreamKey() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Regenerate Key?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Your current stream key will stop working. Make sure to update it in your streaming software.',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stream key regenerated!')),
              );
            },
            child: const Text('Regenerate', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _testMicrophone() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Testing microphone... Speak now!')),
    );
  }
}
