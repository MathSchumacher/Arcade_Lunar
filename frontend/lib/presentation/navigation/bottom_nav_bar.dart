import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with TickerProviderStateMixin {
  // Individual animation controllers for unique effects
  late AnimationController _homeController;
  late AnimationController _liveController;
  late AnimationController _gamesController;
  late AnimationController _chatController;
  late AnimationController _addButtonController;
  late AnimationController _glowController;
  
  bool _isAddButtonPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Home: Elastic bounce (reverted)
    _homeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    // Live: Pulsing signal waves (limited duration)
    _liveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Games: Shake/vibrate
    _gamesController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
    );

    // Chat: Bounce message
    _chatController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Add button rotation
    _addButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Continuous glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _homeController.dispose();
    _liveController.dispose();
    _gamesController.dispose();
    _chatController.dispose();
    _addButtonController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    // Trigger unique animation for each button
    switch (index) {
      case 0:
        _homeController.forward(from: 0).then((_) => _homeController.reverse());
        break;
      case 1:
        // Run loop for 5 seconds then stop
        _liveController.repeat();
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _liveController.stop();
          if (mounted) _liveController.reset();
        });
        break;
      case 3:
        _gamesController.forward(from: 0);
        break;
      case 4:
        _chatController.forward(from: 0);
        break;
    }
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface.withOpacity(0.98),
            AppColors.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHomeButton(),
          _buildLiveButton(),
          _buildCenterButton(),
          _buildGamesButton(),
          _buildChatButton(),
        ],
      ),
    );
  }

  // HOME: High-end Smooth Pulse Animation
  Widget _buildHomeButton() {
    final isSelected = widget.currentIndex == 0;
            
    return GestureDetector(
      onTap: () => _handleTap(0),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _homeController,
        builder: (context, child) {
          // Sophisticated smooth pulse without elastic bounce
          double scale = 1.0;
          if (_homeController.isAnimating) {
             final t = _homeController.value;
             // Smooth rising curve that settles gently
             // Uses a sine curve for a natural "breath" motion
             scale = 1.0 + (math.sin(t * math.pi) * 0.15);
          }
          
          return _buildNavItemBase(
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: isSelected,
            scale: scale,
            customIcon: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle background glow ring that expands
                if (_homeController.isAnimating || isSelected)
                  Opacity(
                    opacity: _homeController.isAnimating 
                        ? (1.0 - _homeController.value) * 0.5 
                        : (isSelected ? 0.2 : 0.0),
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                Icon(
                  Icons.home_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // LIVE: Pulsing signal waves around icon
  Widget _buildLiveButton() {
    final isSelected = widget.currentIndex == 1;
    
    return GestureDetector(
      onTap: () => _handleTap(1),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _liveController,
        builder: (context, child) {
          return _buildNavItemBase(
            icon: Icons.sensors_rounded,
            label: 'Live',
            isSelected: isSelected,
            customIcon: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing waves (only when selected)
                if (isSelected) ...[
                  // Outer wave
                  Transform.scale(
                    scale: 1.0 + (_liveController.value * 0.4),
                    child: Opacity(
                      opacity: 1.0 - _liveController.value,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Inner wave (delayed)
                  Transform.scale(
                    scale: 1.0 + ((_liveController.value + 0.5) % 1.0) * 0.3,
                    child: Opacity(
                      opacity: 1.0 - ((_liveController.value + 0.5) % 1.0),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                Icon(
                  Icons.sensors_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  // GAMES: Controller shake/vibrate
  Widget _buildGamesButton() {
    final isSelected = widget.currentIndex == 3;
    
    return GestureDetector(
      onTap: () => _handleTap(3),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _gamesController,
        builder: (context, child) {
          // Shake effect
          double offsetX = 0;
          double rotation = 0;
          if (_gamesController.isAnimating) {
            final t = _gamesController.value;
            // Multiple quick shakes
            offsetX = math.sin(t * math.pi * 8) * 3 * (1 - t);
            rotation = math.sin(t * math.pi * 6) * 0.1 * (1 - t);
          }
          
          return _buildNavItemBase(
            icon: Icons.sports_esports_rounded,
            label: 'Games',
            isSelected: isSelected,
            customIcon: Transform.translate(
              offset: Offset(offsetX, 0),
              child: Transform.rotate(
                angle: rotation,
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // CHAT: Message bubble pop/bounce
  Widget _buildChatButton() {
    final isSelected = widget.currentIndex == 4;
    
    return GestureDetector(
      onTap: () => _handleTap(4),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _chatController,
        builder: (context, child) {
          // Bounce up and settle
          double offsetY = 0;
          double scale = 1.0;
          if (_chatController.isAnimating) {
            final t = _chatController.value;
            // Pop up then bounce down
            if (t < 0.4) {
              offsetY = -8 * (t / 0.4);
              scale = 1.0 + (t / 0.4) * 0.2;
            } else {
              final bounce = (t - 0.4) / 0.6;
              offsetY = -8 * (1 - bounce);
              scale = 1.2 - bounce * 0.2;
            }
          }
          
          return _buildNavItemBase(
            icon: Icons.chat_bubble_rounded,
            label: 'Chat',
            isSelected: isSelected,
            customIcon: Transform.translate(
              offset: Offset(0, offsetY),
              child: Transform.scale(
                scale: scale,
                child: Icon(
                  Icons.chat_bubble_rounded,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildNavItemBase({
    required IconData icon,
    required String label,
    required bool isSelected,
    double scale = 1.0,
    Widget? customIcon,
  }) {
    return SizedBox(
      width: 55,
      height: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: isSelected ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(_glowController.value * 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ) : null,
                child: Transform.scale(
                  scale: scale,
                  child: customIcon ?? Icon(
                    icon,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isAddButtonPressed = true);
        _addButtonController.forward();
      },
      onTapUp: (_) {
        setState(() => _isAddButtonPressed = false);
        _addButtonController.reverse();
        widget.onTap(2);
      },
      onTapCancel: () {
        setState(() => _isAddButtonPressed = false);
        _addButtonController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowController, _addButtonController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _isAddButtonPressed ? 2 : -6),
            child: Transform.scale(
              scale: _isAddButtonPressed ? 0.9 : 1.0,
              child: Transform.rotate(
                angle: _addButtonController.value * math.pi / 4,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(_glowController.value * 0.7),
                        blurRadius: _isAddButtonPressed ? 8 : 20,
                        spreadRadius: _isAddButtonPressed ? 0 : 2,
                        offset: Offset(0, _isAddButtonPressed ? 2 : 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
