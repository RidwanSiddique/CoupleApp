import 'package:flutter/widgets.dart';

import 'sak_motion.dart';

/// Wraps a child in a gentle, infinite scale-pulse.
/// Very small delta (0.998 ↔ 1.002 by default) — meant to be *felt*, not seen.
///
/// Collapses to a static child when reduced motion is on.
class SakBreathing extends StatefulWidget {
  const SakBreathing({
    super.key,
    required this.child,
    this.minScale = 0.998,
    this.maxScale = 1.002,
    this.period = SakMotion.breathe,
    this.opacityDelta = 0.02,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration period;
  final double opacityDelta;

  @override
  State<SakBreathing> createState() => _SakBreathingState();
}

class _SakBreathingState extends State<SakBreathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SakMotion.motionEnabled(context)) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SakMotion.motionEnabled(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = widget.minScale + (widget.maxScale - widget.minScale) * t;
        final opacity = 1.0 - widget.opacityDelta * (1 - t);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}
