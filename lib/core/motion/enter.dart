import 'package:flutter/widgets.dart';

import 'sak_motion.dart';

/// Wraps a widget in a one-shot entrance animation: fade + subtle y-slide.
///
/// Honors `MediaQuery.disableAnimationsOf`.
class SakEnter extends StatefulWidget {
  const SakEnter({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = SakMotion.gentle,
    this.slideFrom = 12.0,
    this.curve = SakMotion.enter,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideFrom;
  final Curve curve;

  @override
  State<SakEnter> createState() => _SakEnterState();
}

class _SakEnterState extends State<SakEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SakMotion.motionEnabled(context)) {
      // Reduced motion: instant reveal.
      return widget.child;
    }
    final anim = CurvedAnimation(parent: _controller, curve: widget.curve);
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * widget.slideFrom),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
