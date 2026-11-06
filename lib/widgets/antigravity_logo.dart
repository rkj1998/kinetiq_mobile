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
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerBoost() {
    if (!widget.isInteractive) return;
    setState(() => _boost = 2.4);
    Future.delayed(const Duration(milliseconds: 900), () {
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
            painter: _AntigravityPainter(
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

class _AntigravityPainter extends CustomPainter {
  final double progress;
  final double boost;
  final AppThemeConfig theme;

  _AntigravityPainter({
    required this.progress,
    required this.boost,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final primary = theme.primaryAccent;
    final secondary = theme.secondaryAccent;

    // 1. Soft ethereal aura glow
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: theme.isDark ? 0.35 : 0.22),
          secondary.withValues(alpha: theme.isDark ? 0.15 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.15));
    canvas.drawCircle(center, radius * 1.15, auraPaint);

    // 2. Outer kinetic orbital ring 1 (Clockwise)
    final ring1Angle = progress * 2 * math.pi * boost;
    final ring1Paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.038)
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: [
          primary.withValues(alpha: 0.1),
          primary,
          secondary,
          primary.withValues(alpha: 0.1),
        ],
        transform: GradientRotation(ring1Angle),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.85));

    canvas.drawCircle(center, radius * 0.85, ring1Paint);

    // Outer orbiting micro-nodes
    for (int i = 0; i < 3; i++) {
      final angle = ring1Angle + (i * 2 * math.pi / 3);
      final nodePos = Offset(
        center.dx + radius * 0.85 * math.cos(angle),
        center.dy + radius * 0.85 * math.sin(angle),
      );
      final nodePaint = Paint()
        ..color = (i == 0 ? secondary : primary)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodePos, math.max(2.2, size.width * 0.045), nodePaint);
    }

    // 3. Counter-rotating inner kinetic ring 2 (Antigravity tilt)
    final ring2Angle = -progress * 2 * math.pi * 1.4 * boost;
    final ring2Rect = Rect.fromCenter(
      center: center,
      width: radius * 1.25,
      height: radius * 0.95,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.translate(-center.dx, -center.dy);

    final ring2Paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, size.width * 0.032)
      ..shader = SweepGradient(
        colors: [
          secondary.withValues(alpha: 0.2),
          secondary,
          primary.withValues(alpha: 0.2),
        ],
        transform: GradientRotation(ring2Angle),
      ).createShader(ring2Rect);
    canvas.drawOval(ring2Rect, ring2Paint);
    canvas.restore();

    // 4. Center Singularity / Quantum Core
    final pulse = math.sin(progress * 4 * math.pi) * 0.08 + 1.0;
    final coreRadius = radius * 0.38 * pulse;

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          secondary,
          primary,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));

    canvas.drawCircle(center, coreRadius, corePaint);

    // 5. Stylized Antigravity 'K' / Spark glyph
    final glyphPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, size.width * 0.042)
      ..strokeCap = StrokeCap.round;

    final glyphScale = size.width * 0.16;
    // Vertical stem
    canvas.drawLine(
      Offset(center.dx - glyphScale * 0.45, center.dy - glyphScale * 0.8),
      Offset(center.dx - glyphScale * 0.45, center.dy + glyphScale * 0.8),
      glyphPaint,
    );
    // Upper diagonal arm
    canvas.drawLine(
      Offset(center.dx - glyphScale * 0.35, center.dy),
      Offset(center.dx + glyphScale * 0.65, center.dy - glyphScale * 0.8),
      glyphPaint,
    );
    // Lower diagonal arm
    canvas.drawLine(
      Offset(center.dx - glyphScale * 0.15, center.dy + glyphScale * 0.15),
      Offset(center.dx + glyphScale * 0.65, center.dy + glyphScale * 0.8),
      glyphPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _AntigravityPainter oldDelegate) => true;
}
