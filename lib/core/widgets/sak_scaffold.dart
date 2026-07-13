import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'hijri_date.dart';

class SakScaffold extends StatelessWidget {
  const SakScaffold({
    super.key,
    required this.child,
    this.title,
    this.showDualDate = false,
    this.actions,
    this.leading,
    this.padded = true,
  });

  final Widget child;
  final String? title;
  final bool showDualDate;
  final List<Widget>? actions;
  final Widget? leading;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (title == null && !showDualDate && actions == null)
          ? null
          : AppBar(
              leading: leading,
              actions: actions,
              titleSpacing: SakSpace.lg,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  if (showDualDate) const HijriDate(),
                ],
              ),
              toolbarHeight: showDualDate ? 72 : kToolbarHeight,
            ),
      body: SafeArea(
        child: Padding(
          padding: padded
              ? const EdgeInsets.symmetric(horizontal: SakSpace.lg)
              : EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
