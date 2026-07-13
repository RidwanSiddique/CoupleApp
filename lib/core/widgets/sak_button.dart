import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum SakButtonVariant { filled, outlined, text }

class SakButton extends StatelessWidget {
  const SakButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SakButtonVariant.filled,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SakButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final onTap = loading ? null : onPressed;

    Widget child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                variant == SakButtonVariant.filled
                    ? scheme.onPrimary
                    : scheme.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: SakSpace.sm),
              ],
              Text(label),
            ],
          );

    final padding = const EdgeInsets.symmetric(
      horizontal: SakSpace.xl,
      vertical: SakSpace.md + 2,
    );
    final radius = BorderRadius.circular(SakRadius.pill);

    switch (variant) {
      case SakButtonVariant.filled:
        return FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: radius),
            textStyle: theme.textTheme.labelLarge,
            minimumSize: expand ? const Size.fromHeight(48) : null,
          ),
          child: child,
        );
      case SakButtonVariant.outlined:
        return OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: radius),
            side: BorderSide(color: scheme.outline),
            textStyle: theme.textTheme.labelLarge,
            minimumSize: expand ? const Size.fromHeight(48) : null,
          ),
          child: child,
        );
      case SakButtonVariant.text:
        return TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: padding,
            textStyle: theme.textTheme.labelLarge,
          ),
          child: child,
        );
    }
  }
}
