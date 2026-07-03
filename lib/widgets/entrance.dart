import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// One-shot entrance: fade + 12px slide-up, staggered by [index] (40ms per
/// step). Animates ONLY Opacity + Transform — never decorations, so it can
/// never hit the BoxShadow-lerp assert that overshoot curves trigger (see
/// home_shell nav history). Curve is Motion.emphasized on purpose; do not
/// switch to Motion.spring.
///
/// Plays once per State lifetime — inside an IndexedStack tab the animation
/// runs on first build only, which is the intended "app comes alive" moment.
/// Under MediaQuery.disableAnimations the child renders directly.
class Entrance extends StatefulWidget {
  final int index;
  final Widget child;
  const Entrance({super.key, this.index = 0, required this.child});

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );
  late final CurvedAnimation _a =
      CurvedAnimation(parent: _c, curve: Motion.emphasized);
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
      return;
    }
    // Cap the stagger so far-down cards don't feel laggy when scrolled to.
    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 10));
    Future<void>.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c.isCompleted) return widget.child;
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - _a.value)),
          child: child,
        ),
      ),
    );
  }
}
