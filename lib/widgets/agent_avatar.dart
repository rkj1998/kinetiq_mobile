import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/agent_character.dart';

class AgentAvatar extends StatefulWidget {
  final AgentCharacter character;
  final AgentMood mood;
  final double size;
  final bool showBadge;

  const AgentAvatar({
    super.key,
    required this.character,
    this.mood = AgentMood.idle,
    this.size = 56,
    this.showBadge = false,
  });

  @override
  State<AgentAvatar> createState() => _AgentAvatarState();
}

class _AgentAvatarState extends State<AgentAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant AgentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == AgentMood.thinking || widget.mood == AgentMood.executing) {
      _animController.duration = const Duration(milliseconds: 900);
      if (!_animController.isAnimating) _animController.repeat();
    } else {
      _animController.duration = const Duration(seconds: 3);
      if (!_animController.isAnimating) _animController.repeat();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = _animController.value;
        final pulse = math.sin(progress * 2 * math.pi) * 0.08 + 1.0;
        final rotation = progress * 2 * math.pi;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Ambient Aura Glow
            Container(
              width: widget.size * (widget.mood == AgentMood.thinking ? 1.4 : 1.15),
              height: widget.size * (widget.mood == AgentMood.thinking ? 1.4 : 1.15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.character.glowColor.withValues(
                      alpha: widget.mood == AgentMood.thinking ? 0.6 : 0.35,
                    ),
                    blurRadius: widget.mood == AgentMood.thinking ? 24 : 14,
                    spreadRadius: widget.mood == AgentMood.thinking ? 4 : 1,
                  ),
                ],
              ),
            ),

            // Rotating Cyber Orbit Ring when Thinking / Executing
            if (widget.mood == AgentMood.thinking || widget.mood == AgentMood.executing)
              Transform.rotate(
                angle: rotation,
                child: CustomPaint(
                  size: Size(widget.size * 1.25, widget.size * 1.25),
                  painter: _CyberOrbitPainter(color: widget.character.glowColor),
                ),
              ),

            // Expressive Bot Face Canvas
            Transform.scale(
              scale: widget.mood == AgentMood.thinking ? pulse : 1.0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.character.primaryColor,
                      widget.character.secondaryColor,
                      const Color(0xFF0F172A),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _BotFacePainter(
                    characterId: widget.character.id,
                    mood: widget.mood,
                    eyeGlowColor: widget.character.glowColor,
                    progress: progress,
                  ),
                ),
              ),
            ),

            // Status Indicator Badge
            if (widget.showBadge)
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor(),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusBadgeColor().withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getStatusBadgeColor() {
    switch (widget.mood) {
      case AgentMood.thinking:
        return const Color(0xFFF59E0B);
      case AgentMood.executing:
        return const Color(0xFF06B6D4);
      case AgentMood.error:
        return const Color(0xFFEF4444);
      case AgentMood.speaking:
        return const Color(0xFF8B5CF6);
      case AgentMood.idle:
      default:
        return const Color(0xFF10B981);
    }
  }
}

class _CyberOrbitPainter extends CustomPainter {
  final Color color;
  _CyberOrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw dashed cyber arcs
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 0.7,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * 0.7,
      false,
      paint,
    );

    // Orbiting particle beads
    final beadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx + radius, center.dy), 3.0, beadPaint);
    canvas.drawCircle(Offset(center.dx - radius, center.dy), 3.0, beadPaint);
  }

  @override
  bool shouldRepaint(covariant _CyberOrbitPainter oldDelegate) => true;
}

class _BotFacePainter extends CustomPainter {
  final String characterId;
  final AgentMood mood;
  final Color eyeGlowColor;
  final double progress;

  _BotFacePainter({
    required this.characterId,
    required this.mood,
    required this.eyeGlowColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Head Visor Plate
    final visorPaint = Paint()
      ..color = const Color(0xFF0A0C14).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: size.width * 0.76, height: size.height * 0.46),
      Radius.circular(size.width * 0.22),
    );
    canvas.drawRRect(visorRect, visorPaint);

    final eyePaint = Paint()
      ..color = (mood == AgentMood.error) ? const Color(0xFFEF4444) : eyeGlowColor
      ..style = PaintingStyle.fill;

    final eyeSpacing = size.width * 0.16;
    final eyeY = cy;

    // Character-specific custom facial cyber aesthetics
    switch (characterId) {
      case 'antigravity':
        // Antigravity has friendly Bitmoji-style expressive eyes with sweet curved blinks
        final blink = (progress > 0.46 && progress < 0.54);
        final eyeW = size.width * 0.14;
        final eyeH = blink ? 2.5 : size.height * 0.14;

        if (blink) {
          final smilePaint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(2.0, size.width * 0.05)
            ..strokeCap = StrokeCap.round;
          final leftSmile = Path()
            ..moveTo(cx - eyeSpacing - eyeW * 0.5, eyeY)
            ..quadraticBezierTo(cx - eyeSpacing, eyeY + 3, cx - eyeSpacing + eyeW * 0.5, eyeY);
          canvas.drawPath(leftSmile, smilePaint);
          final rightSmile = Path()
            ..moveTo(cx + eyeSpacing - eyeW * 0.5, eyeY)
            ..quadraticBezierTo(cx + eyeSpacing, eyeY + 3, cx + eyeSpacing + eyeW * 0.5, eyeY);
          canvas.drawPath(rightSmile, smilePaint);
        } else {
          final lensRRect = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx - eyeSpacing, eyeY), width: eyeW, height: eyeH),
            Radius.circular(size.width * 0.07),
          );
          final lensRRectRight = RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + eyeSpacing, eyeY), width: eyeW, height: eyeH),
            Radius.circular(size.width * 0.07),
          );
          canvas.drawRRect(lensRRect, eyePaint);
          canvas.drawRRect(lensRRectRight, eyePaint);

          // Sparkle catchlights
          final coreDotPaint = Paint()..color = Colors.white;
          canvas.drawCircle(Offset(cx - eyeSpacing - 2, eyeY - 2), 2.8, coreDotPaint);
          canvas.drawCircle(Offset(cx + eyeSpacing - 2, eyeY - 2), 2.8, coreDotPaint);
        }
        break;

      case 'titan':
        // Titan has wide tactical cyber optics
        final eyeW = size.width * 0.15;
        final eyeH = (mood == AgentMood.thinking) ? size.height * 0.04 : size.height * 0.10;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - eyeSpacing, eyeY), width: eyeW, height: eyeH), const Radius.circular(2)),
          eyePaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + eyeSpacing, eyeY), width: eyeW, height: eyeH), const Radius.circular(2)),
          eyePaint,
        );
        break;

      case 'cipher':
        // Cipher has dual neon scanning rings
        final eyeRadius = size.width * 0.08;
        final ringPaint = Paint()
          ..color = eyeGlowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), eyeRadius, ringPaint);
        canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), eyeRadius, ringPaint);
        canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), 2.5, eyePaint);
        canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), 2.5, eyePaint);
        break;

      case 'spark':
        // Spark has energetic angular lightning eyes
        final eyePath = Path();
        eyePath.moveTo(cx - eyeSpacing - 5, eyeY - 6);
        eyePath.lineTo(cx - eyeSpacing + 5, eyeY);
        eyePath.lineTo(cx - eyeSpacing - 5, eyeY + 6);
        canvas.drawPath(eyePath, eyePaint);

        final eyePathRight = Path();
        eyePathRight.moveTo(cx + eyeSpacing + 5, eyeY - 6);
        eyePathRight.lineTo(cx + eyeSpacing - 5, eyeY);
        eyePathRight.lineTo(cx + eyeSpacing + 5, eyeY + 6);
        canvas.drawPath(eyePathRight, eyePaint);
        break;

      case 'muse':
      default:
        // Muse has bright expressive anime-style cyber eyes
        final blink = (progress > 0.48 && progress < 0.52);
        final eyeR = blink ? 1.5 : size.width * 0.085;
        canvas.drawCircle(Offset(cx - eyeSpacing, eyeY), eyeR, eyePaint);
        canvas.drawCircle(Offset(cx + eyeSpacing, eyeY), eyeR, eyePaint);

        if (!blink) {
          final glintPaint = Paint()..color = Colors.white;
          canvas.drawCircle(Offset(cx - eyeSpacing - 2, eyeY - 2), eyeR * 0.35, glintPaint);
          canvas.drawCircle(Offset(cx + eyeSpacing - 2, eyeY - 2), eyeR * 0.35, glintPaint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BotFacePainter oldDelegate) => true;
}
