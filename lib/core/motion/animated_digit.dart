import 'package:flutter/material.dart';

import 'sak_motion.dart';

/// A single digit (0–9) that transitions with a vertical slide + fade
/// rather than an instant swap. Odometer feel.
class SakAnimatedDigit extends StatelessWidget {
  const SakAnimatedDigit({
    super.key,
    required this.digit,
    this.style,
  });

  /// Value to render, 0–9 inclusive. Any other value renders as-is.
  final int digit;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (style ?? DefaultTextStyle.of(context).style)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    final content = Text(
      digit.toString(),
      style: effectiveStyle,
      textAlign: TextAlign.center,
    );

    if (!SakMotion.motionEnabled(context)) {
      return content;
    }

    return AnimatedSwitcher(
      duration: SakMotion.standard,
      switchInCurve: SakMotion.enter,
      switchOutCurve: SakMotion.enter,
      transitionBuilder: (child, animation) {
        final inbound = child.key == ValueKey(digit);
        final slide = Tween<Offset>(
          begin: Offset(0, inbound ? 0.4 : -0.4),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(
            position: slide,
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      child: KeyedSubtree(key: ValueKey(digit), child: content),
    );
  }
}

/// Renders a fixed-width row of digits from a number, animating each digit
/// independently. Handles negative signs and leading zeros via [minDigits].
class SakDigitRow extends StatelessWidget {
  const SakDigitRow({
    super.key,
    required this.value,
    this.style,
    this.minDigits = 2,
  });

  final int value;
  final TextStyle? style;
  final int minDigits;

  @override
  Widget build(BuildContext context) {
    final text = value.abs().toString().padLeft(minDigits, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value < 0)
          Text('-', style: style),
        for (var i = 0; i < text.length; i++)
          SakAnimatedDigit(
            digit: int.parse(text[i]),
            style: style,
          ),
      ],
    );
  }
}
