import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class SakCard extends StatelessWidget {
  const SakCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SakSpace.lg),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(SakRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SakRadius.lg),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SakRadius.lg),
            border: Border.all(
              color: isDark ? SakColors.dividerDark : SakColors.divider,
            ),
            boxShadow:
                isDark ? SakElevation.cardDark : SakElevation.card,
          ),
          child: child,
        ),
      ),
    );
  }
}
