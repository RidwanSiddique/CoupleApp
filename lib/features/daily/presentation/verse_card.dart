import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/daily_content_providers.dart';

/// A card showing today's verse: Arabic, translation, source. Taps into a
/// full-screen reader.
class VerseCard extends ConsumerWidget {
  const VerseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(dailyContentProvider);

    return async.when(
      loading: () => const _VerseSkeleton(),
      error: (e, _) => _VerseError(theme: theme),
      data: (content) {
        final v = content?.verse;
        if (v == null) return _VerseError(theme: theme);
        return SakCard(
          onTap: () => context.push('/home/verse'),
          padding: const EdgeInsets.all(SakSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verse of the day',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: SakSpace.md),
              Text(
                v.arabicText,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: SakTypography.arabicText(
                  fontSize: 22,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: SakSpace.md),
              Text(
                v.translation,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: SakSpace.md),
              Row(
                children: [
                  Text(
                    v.reference,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.55),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Read',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VerseSkeleton extends StatelessWidget {
  const _VerseSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SakSpace.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(SakRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SakShimmerBox(width: 120, height: 12, radius: SakRadius.xs),
          SizedBox(height: SakSpace.md),
          SakShimmerBox(height: 60, radius: SakRadius.sm),
          SizedBox(height: SakSpace.md),
          SakShimmerBox(height: 16, radius: SakRadius.xs),
          SizedBox(height: SakSpace.xs),
          SakShimmerBox(height: 16, radius: SakRadius.xs),
        ],
      ),
    );
  }
}

class _VerseError extends StatelessWidget {
  const _VerseError({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SakCard(
      padding: const EdgeInsets.all(SakSpace.xl),
      child: Text(
        "Couldn't load today's verse.",
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
