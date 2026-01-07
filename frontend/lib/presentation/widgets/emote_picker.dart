import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Emote Picker Widget for Stream Chat
/// Shows a grid of emotes that can be selected
class EmotePicker extends StatelessWidget {
  final Function(String) onEmoteSelected;
  final VoidCallback? onClose;

  const EmotePicker({
    super.key,
    required this.onEmoteSelected,
    this.onClose,
  });

  // Standard emotes (Unicode)
  static const List<String> standardEmotes = [
    '😀', '😂', '🤣', '😍', '🥰', '😘', '😎', '🤩',
    '😭', '😱', '😡', '🤔', '🙄', '😴', '🤯', '🥵',
    '👍', '👎', '👏', '🙌', '🎉', '🔥', '❤️', '💯',
    '🎮', '🕹️', '🏆', '⚔️', '🛡️', '💎', '⭐', '🌟',
    'GG', 'EZ', 'POG', 'KEKW', 'LUL', 'F', 'W', 'L',
  ];

  // Gaming-specific emotes (text-based)
  static const List<Map<String, String>> gamingEmotes = [
    {'code': ':gg:', 'display': 'GG'},
    {'code': ':wp:', 'display': 'WP'},
    {'code': ':ez:', 'display': 'EZ'},
    {'code': ':pog:', 'display': 'POG'},
    {'code': ':hype:', 'display': '🔥'},
    {'code': ':love:', 'display': '❤️'},
    {'code': ':rip:', 'display': 'RIP'},
    {'code': ':oof:', 'display': 'OOF'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emotes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onClose != null)
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
          
          // Emotes grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: standardEmotes.length,
              itemBuilder: (context, index) {
                final emote = standardEmotes[index];
                return _buildEmoteButton(emote);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmoteButton(String emote) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onEmoteSelected(emote),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            emote,
            style: TextStyle(
              fontSize: emote.length <= 2 ? 20 : 12,
              fontWeight: emote.length > 2 ? FontWeight.bold : FontWeight.normal,
              color: emote.length > 2 ? AppColors.primary : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline Emote Button for chat input
class EmoteButton extends StatelessWidget {
  final VoidCallback onTap;

  const EmoteButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        Icons.emoji_emotions_outlined,
        color: AppColors.textSecondary,
      ),
      tooltip: 'Emotes',
    );
  }
}
