import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// Fires a one-shot confetti burst over the whole screen, then cleans itself
/// up. Pure Flutter (no plugin) — use for win moments: skipping a want,
/// reclaiming time, hitting a goal.
void celebrate(BuildContext context, {Offset? origin}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  HapticFeedback.mediumImpact();

  final size = MediaQuery.of(context).size;
  final from = origin ?? Offset(size.width / 2, size.height * 0.32);

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ConfettiLayer(
      origin: from,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _Particle {
  final Color color;
  final double angle; // radians
  final double speed; // px/s
  final double rotation;
  final double spin;
  final double size;
  _Particle(Random r)
      : color = _palette[r.nextInt(_palette.length)],
        angle = -pi / 2 + (r.nextDouble() - 0.5) * pi, // mostly upward fan
        speed = 320 + r.nextDouble() * 480,
        rotation = r.nextDouble() * pi,
        spin = (r.nextDouble() - 0.5) * 14,
        size = 7 + r.nextDouble() * 7;

  static const _palette = [
    AppColors.accent,
    AppColors.money,
    AppColors.time,
    AppColors.positive,
    Color(0xFFB14DFF),
    Color(0xFFFF7E5F),
  ];
}

class _ConfettiLayer extends StatefulWidget {
  final Offset origin;
  final VoidCallback onDone;
  const _ConfettiLayer({required this.origin, required this.onDone});

  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final r = Random();
    _particles = List.generate(44, (_) => _Particle(r));
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            origin: widget.origin,
            t: _c.value,
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final Offset origin;
  final double t; // 0..1
  static const double _gravity = 900;

  _ConfettiPainter({
    required this.particles,
    required this.origin,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final time = t * 1.4; // seconds
    final fade = (1 - t).clamp(0.0, 1.0);
    final paint = Paint();
    for (final p in particles) {
      final vx = cos(p.angle) * p.speed;
      final vy = sin(p.angle) * p.speed;
      final dx = vx * time;
      final dy = vy * time + 0.5 * _gravity * time * time;
      final pos = origin + Offset(dx, dy);

      paint.color = p.color.withValues(alpha: fade);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.rotation + p.spin * time);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
