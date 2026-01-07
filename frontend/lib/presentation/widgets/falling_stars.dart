import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated starry sky with twinkling stars and shooting stars
class FallingStars extends StatefulWidget {
  final Widget child;
  final int starCount;

  const FallingStars({
    super.key,
    required this.child,
    this.starCount = 50,
  });

  @override
  State<FallingStars> createState() => _FallingStarsState();
}

class _FallingStarsState extends State<FallingStars>
    with TickerProviderStateMixin {
  late List<Star> stars;
  late List<ShootingStar> shootingStars;
  late AnimationController _controller;
  final random = math.Random();

  @override
  void initState() {
    super.initState();
    stars = List.generate(widget.starCount, (_) => Star.random());
    shootingStars = [];
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    _controller.addListener(_updateAnimation);
  }

  void _updateAnimation() {
    setState(() {
      // Update twinkling stars
      for (var star in stars) {
        star.twinkle();
      }
      
      // Update shooting stars
      for (var ss in shootingStars) {
        ss.update();
      }
      shootingStars.removeWhere((ss) => ss.isDead);
      
      // Randomly spawn new shooting stars
      if (random.nextDouble() < 0.008 && shootingStars.length < 3) {
        shootingStars.add(ShootingStar.random());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        // Main content on bottom
        widget.child,
        // All stars overlay - wrapped in single IgnorePointer
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              size: size,
              painter: StarFieldPainter(stars: stars),
            ),
          ),
        ),
        // Shooting stars - each inside Positioned, then IgnorePointer wraps the content
        ...shootingStars.map((ss) => Positioned(
          left: ss.x * size.width,
          top: ss.y * size.height,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: ss.angle,
              child: Opacity(
                opacity: ss.opacity,
                child: Container(
                  width: ss.length,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.6, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }
}

/// Painter for static twinkling stars
class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  
  StarFieldPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final paint = Paint()
        ..color = star.color.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;
      
      final x = star.x * size.width;
      final y = star.y * size.height;
      
      // Draw 4-pointed star shape
      _drawStar(canvas, Offset(x, y), star.size, paint);
      
      // Add glow effect for brighter stars
      if (star.opacity > 0.6) {
        final glowPaint = Paint()
          ..color = star.color.withOpacity(star.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(x, y), star.size * 1.5, glowPaint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const points = 4;
    final outerRadius = size;
    final innerRadius = size * 0.4;
    
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * math.pi / points) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StarFieldPainter oldDelegate) => true;
}

/// Twinkling star data
class Star {
  double x;
  double y;
  double size;
  double opacity;
  double targetOpacity;
  Color color;

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.targetOpacity,
    required this.color,
  });

  factory Star.random() {
    final random = math.Random();
    final colors = [
      Colors.white,
      const Color(0xFFFFE4B5), // Warm white
      const Color(0xFFADD8E6), // Cool blue  
      const Color(0xFFE6E6FA), // Lavender
      const Color(0xFFFFF8DC), // Cornsilk
    ];
    
    return Star(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 3 + 1, // 1-4 px
      opacity: random.nextDouble() * 0.5 + 0.3,
      targetOpacity: random.nextDouble() * 0.5 + 0.3,
      color: colors[random.nextInt(colors.length)],
    );
  }

  void twinkle() {
    final random = math.Random();
    
    // Smoothly interpolate towards target opacity
    opacity += (targetOpacity - opacity) * 0.1;
    
    // Occasionally set new target
    if (random.nextDouble() < 0.02) {
      targetOpacity = random.nextDouble() * 0.6 + 0.2;
    }
  }
}

/// Shooting star data
class ShootingStar {
  double x;
  double y;
  double speed;
  double angle;
  double length;
  double opacity;
  double life;

  ShootingStar({
    required this.x,
    required this.y,
    required this.speed,
    required this.angle,
    required this.length,
    required this.opacity,
    required this.life,
  });

  factory ShootingStar.random() {
    final random = math.Random();
    
    // Start from top-left area, moving diagonally
    return ShootingStar(
      x: random.nextDouble() * 0.6,
      y: random.nextDouble() * 0.3,
      speed: random.nextDouble() * 0.015 + 0.01,
      angle: math.pi / 4 + (random.nextDouble() - 0.5) * 0.3, // ~45 degrees
      length: random.nextDouble() * 60 + 40, // 40-100 px trail
      opacity: 1.0,
      life: 1.0,
    );
  }

  void update() {
    // Move diagonally
    x += math.cos(angle) * speed;
    y += math.sin(angle) * speed;
    
    // Fade out over time
    life -= 0.02;
    opacity = life.clamp(0.0, 1.0);
  }

  bool get isDead => life <= 0 || x > 1.2 || y > 1.2;
}
