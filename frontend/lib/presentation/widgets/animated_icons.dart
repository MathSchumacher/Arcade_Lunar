import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated Search Icon with pulse and glow effects
class AnimatedSearchIcon extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final bool isActive;

  const AnimatedSearchIcon({
    super.key,
    required this.onTap,
    this.size = 24,
    this.isActive = false,
  });

  @override
  State<AnimatedSearchIcon> createState() => _AnimatedSearchIconState();
}

class _AnimatedSearchIconState extends State<AnimatedSearchIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() => _isHovered = true);
    _controller.forward();
  }

  void _onHoverExit() {
    setState(() => _isHovered = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isHovered || widget.isActive
                        ? AppColors.primary.withOpacity(0.15)
                        : Colors.transparent,
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.search,
                    size: widget.size,
                    color: _isHovered || widget.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animated Notification Bell with bounce and badge
class AnimatedNotificationIcon extends StatefulWidget {
  final VoidCallback onTap;
  final int notificationCount;
  final double size;

  const AnimatedNotificationIcon({
    super.key,
    required this.onTap,
    this.notificationCount = 0,
    this.size = 24,
  });

  @override
  State<AnimatedNotificationIcon> createState() => _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.1), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0), weight: 25),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    // Auto-shake if there are notifications
    if (widget.notificationCount > 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _shakeController.forward().then((_) => _shakeController.reset());
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedNotificationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notificationCount > oldWidget.notificationCount) {
      _bounceController.forward().then((_) => _bounceController.reset());
      _shakeController.forward().then((_) => _shakeController.reset());
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() => _isHovered = true);
    _bounceController.forward().then((_) => _bounceController.reset());
  }

  void _onHoverExit() {
    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: GestureDetector(
        onTap: () {
          _bounceController.forward().then((_) => _bounceController.reset());
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_bounceController, _shakeController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnimation.value,
              child: Transform.rotate(
                angle: _shakeAnimation.value,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isHovered
                            ? AppColors.secondary.withOpacity(0.15)
                            : Colors.transparent,
                        boxShadow: _isHovered
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        widget.notificationCount > 0
                            ? Icons.notifications_active
                            : Icons.notifications_outlined,
                        size: widget.size,
                        color: _isHovered || widget.notificationCount > 0
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                      ),
                    ),
                    // Badge
                    if (widget.notificationCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            widget.notificationCount > 99
                                ? '99+'
                                : '${widget.notificationCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Animated Like Button with heart burst effect
class AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;

  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 24,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLiked && !oldWidget.isLiked) {
      _controller.forward().then((_) => _controller.reset());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.isLiked ? Icons.favorite : Icons.favorite_border,
              size: widget.size,
              color: widget.isLiked ? Colors.red : AppColors.textSecondary,
            ),
          );
        },
      ),
    );
  }
}
