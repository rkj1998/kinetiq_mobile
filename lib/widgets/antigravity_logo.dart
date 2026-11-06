import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_theme_config.dart';

class AntigravityLogo extends StatefulWidget {
  final double size;
  final AppThemeConfig theme;
  final bool isInteractive;
  final VoidCallback? onTap;

  const AntigravityLogo({
    super.key,
    this.size = 56,
    required this.theme,
    this.isInteractive = true,
    this.onTap,
  });

  @override
  State<AntigravityLogo> createState() => _AntigravityLogoState();
}

class _AntigravityLogoState extends State<AntigravityLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _boost = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerBoost() {
    if (!widget.isInteractive) return;
    setState(() => _boost = 2.0);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _boost = 1.0);
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerBoost,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _BitmojiCompanionPainter(
              progress: _controller.value,
              boost: _boost,
              theme: widget.theme,
            ),
          );
        },
      ),
    );
  }
}

class _BitmojiCompanionPainter extends CustomPainter {
  final double progress;
  final double boost;
  final AppThemeConfig theme;

  _BitmojiCompanionPainter({
    required this.progress,
    required this.boost,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;
    final primary = theme.primaryAccent;
    final secondary = theme.secondaryAccent;

    // 1. Soft breathing aura glow
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: theme.isDark ? 0.35 : 0.22),
          secondary.withValues(alpha: theme.isDark ? 0.15 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.25));
    canvas.drawCircle(Offset(cx, cy), radius * 1.25, auraPaint);

    // 2. Halo Floating Energy Ring (Bitmoji Antigravity Crown)
    final floatY = math.sin(progress * 2 * math.pi * boost) * (size.height * 0.035);
    final haloCenter = Offset(cx, size.height * 0.16 + floatY);
    final haloRect = Rect.fromCenter(
      center: haloCenter,
      width: size.width * 0.58,
      height: size.height * 0.14,
    );
    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, size.width * 0.04)
      ..shader = SweepGradient(
        colors: [
          primary.withValues(alpha: 0.3),
          primary,
          secondary,
          primary.withValues(alpha: 0.3),
        ],
        transform: GradientRotation(progress * 2 * math.pi * boost),
      ).createShader(haloRect);
    canvas.drawOval(haloRect, haloPaint);

    // 3. Cute Bitmoji Bot Head Sphere
    final headCenter = Offset(cx, cy + floatY * 0.5);
    final headRadius = radius * 0.72;

    final headGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        Color.lerp(Colors.white, primary, 0.18)!,
        Color.lerp(theme.cardColor, primary, 0.28)!,
      ],
    );
    final headPaint = Paint()
      ..shader = headGradient.createShader(Rect.fromCircle(center: headCenter, radius: headRadius))
      ..style = PaintingStyle.fill;

    // Soft drop shadow under head
    canvas.drawCircle(
      Offset(headCenter.dx, headCenter.dy + 3),
      headRadius,
      Paint()
        ..color = (theme.isDark ? Colors.black45 : const Color(0x1F000000))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Main head surface
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Head border highlight
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.035)
      ..color = primary.withValues(alpha: 0.45);
    canvas.drawCircle(headCenter, headRadius, borderPaint);

    // 4. Expressive Visor / Face Screen (Sleek Apple/Bitmoji Pill Shape)
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.04),
        width: headRadius * 1.48,
        height: headRadius * 0.88,
      ),
      Radius.circular(headRadius * 0.44),
    );

    final visorPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(visorRect, visorPaint);

    // Visor subtle glossy reflection
    final glassHighlight = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(visorRect.outerRect);
    canvas.drawRRect(visorRect, glassHighlight);

    // 5. Expressive Bitmoji Eyes with Natural Eye-Blink & Tracking
    final blinkPhase = (progress * 1.5) % 1.0;
    final isBlinking = blinkPhase > 0.46 && blinkPhase < 0.52;

    final eyeSpacing = headRadius * 0.38;
    final eyeY = headCenter.dy + headRadius * 0.04;
    final eyeRadius = headRadius * 0.22;

    final eyeGlowPaint = Paint()
      ..color = secondary
      ..style = PaintingStyle.fill;

    if (isBlinking) {
      // Happy curving blink line
      final blinkPaint = Paint()
        ..color = secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.2, size.width * 0.042)
        ..strokeCap = StrokeCap.round;

      // Left eye curved smile
      final leftPath = Path()
        ..moveTo(headCenter.dx - eyeSpacing - eyeRadius * 0.7, eyeY)
        ..quadraticBezierTo(headCenter.dx - eyeSpacing, eyeY + eyeRadius * 0.4, headCenter.dx - eyeSpacing + eyeRadius * 0.7, eyeY);
      canvas.drawPath(leftPath, blinkPaint);

      // Right eye curved smile
      final rightPath = Path()
        ..moveTo(headCenter.dx + eyeSpacing - eyeRadius * 0.7, eyeY)
        ..quadraticBezierTo(headCenter.dx + eyeSpacing, eyeY + eyeRadius * 0.4, headCenter.dx + eyeSpacing + eyeRadius * 0.7, eyeY);
      canvas.drawPath(rightPath, blinkPaint);
    } else {
      // Big expressive anime/bitmoji eyes with catchlights
      final eyeCenterLeft = Offset(headCenter.dx - eyeSpacing, eyeY);
      final eyeCenterRight = Offset(headCenter.dx + eyeSpacing, eyeY);

      canvas.drawCircle(eyeCenterLeft, eyeRadius, eyeGlowPaint);
      canvas.drawCircle(eyeCenterRight, eyeRadius, eyeGlowPaint);

      // Catchlights / Sparkles in eyes
      final glintPaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(eyeCenterLeft.dx - eyeRadius * 0.32, eyeCenterLeft.dy - eyeRadius * 0.32),
        eyeRadius * 0.42,
        glintPaint,
      );
      canvas.drawCircle(
        Offset(eyeCenterRight.dx - eyeRadius * 0.32, eyeCenterRight.dy - eyeRadius * 0.32),
        eyeRadius * 0.42,
        glintPaint,
      );

      // Secondary smaller micro-sparkle
      canvas.drawCircle(
        Offset(eyeCenterLeft.dx + eyeRadius * 0.28, eyeCenterLeft.dy + eyeRadius * 0.28),
        eyeRadius * 0.20,
        glintPaint,
      );
      canvas.drawCircle(
        Offset(eyeCenterRight.dx + eyeRadius * 0.28, eyeCenterRight.dy + eyeRadius * 0.28),
        eyeRadius * 0.20,
        glintPaint,
      );
    }

    // 6. Cute Blush Cheeks
    final blushPaint = Paint()
      ..color = const Color(0xFFF43F5E).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCenter.dx - eyeSpacing * 1.35, eyeY + eyeRadius * 0.95),
        width: eyeRadius * 0.9,
        height: eyeRadius * 0.5,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCenter.dx + eyeSpacing * 1.35, eyeY + eyeRadius * 0.95),
        width: eyeRadius * 0.9,
        height: eyeRadius * 0.5,
      ),
      blushPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BitmojiCompanionPainter oldDelegate) => true;
}
