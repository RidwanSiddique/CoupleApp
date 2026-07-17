import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/time/prayer_engine.dart';
import '../../../core/widgets/widgets.dart';
import '../../daily/presentation/question_card.dart';
import '../../daily/presentation/verse_card.dart';
import '../../duas/presentation/dua_card.dart';
import '../../gratitude/presentation/gratitude_card.dart';
import '../../location/data/location_service.dart';
import '../../location/domain/location_providers.dart';
import '../../pairing/domain/pairing_providers.dart';
import '../../prayer_log/presentation/prayer_log_card.dart';
import '../../scoring/presentation/scoreboard_card.dart';
import '../domain/home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final own = ref.watch(ownProfileProvider);
    final spouse = ref.watch(spouseProfileProvider);
    final couple = ref.watch(currentCoupleProvider);
    final nextPrayer = ref.watch(nextPrayerProvider);
    // Derive from the profile already watched above rather than watching the
    // separate isWifeProvider — watching both the async profile and a sync
    // provider derived from it in one build re-enters and throws
    // "setState during build".
    final isWife = own.asData?.value?.gender == 'female';
    final locationState = ref.watch(locationControllerProvider);

    // Surface a location-capture failure as a snackbar.
    ref.listen(locationControllerProvider, (prev, next) {
      final err = next.error;
      if (next.hasError && err is LocationFailure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(err.userMessage)));
      }
    });

    final now = DateTime.now();
    final greeting = greetingForHour(now.hour);
    final ownName = own.asData?.value?.displayName;
    final spouseName = spouse.asData?.value?.displayName;
    final profileReady = own.hasValue;

    return SakScaffold(
      padded: false,
      showAppBar: false,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SakSpace.lg,
                SakSpace.md,
                SakSpace.lg,
                SakSpace.md,
              ),
              sliver: SliverToBoxAdapter(
                child: SakEnter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TodayCrescent(
                        size: 20,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: SakSpace.sm),
                      Expanded(child: HijriDate(date: now)),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: 'Settings',
                        onPressed: () => context.go('/home/settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: SakSpace.lg),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: SakSpace.sm),
                  child: profileReady
                      ? _Greeting(
                          greeting: greeting,
                          name: ownName ?? '',
                          spouseName: spouseName,
                        )
                      : const _GreetingSkeleton(),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SakSpace.xxl),
            ),

            // Next prayer card
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: SakSpace.lg),
              sliver: SliverToBoxAdapter(
                child: SakEnter(
                  delay: const Duration(milliseconds: 380),
                  child: profileReady
                      ? _NextPrayerCard(
                          next: nextPrayer,
                          hasLocation:
                              own.asData?.value?.latitude != null &&
                                  own.asData?.value?.longitude != null,
                          busy: locationState.isLoading,
                          onSetLocation: () => ref
                              .read(locationControllerProvider.notifier)
                              .captureAndSave(),
                        )
                      : const _NextPrayerSkeleton(),
                ),
              ),
            ),

            // Feature cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SakSpace.lg,
                SakSpace.xl,
                SakSpace.lg,
                SakSpace.xl,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SakStagger(
                    initialDelay: const Duration(milliseconds: 460),
                    stagger: const Duration(milliseconds: 90),
                    slideFrom: 16,
                    children: [
                      const PrayerLogCard(),
                      const SizedBox(height: SakSpace.md),
                      const ScoreboardCard(),
                      const SizedBox(height: SakSpace.md),
                      if (isWife) ...[
                        const _CycleTile(),
                        const SizedBox(height: SakSpace.md),
                      ],
                      _CareTile(isWife: isWife),
                      const SizedBox(height: SakSpace.md),
                      const VerseCard(),
                      const SizedBox(height: SakSpace.md),
                      const QuestionCard(),
                      const SizedBox(height: SakSpace.md),
                      const GratitudeCard(),
                      const SizedBox(height: SakSpace.md),
                      const DuaCard(),
                    ],
                  ),
                  const SizedBox(height: SakSpace.xxxl),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: SakSpace.xxl),
                  child: SakEnter(
                    delay: const Duration(milliseconds: 900),
                    child: Text(
                      couple.asData?.value == null
                          ? 'Getting things ready…'
                          : 'Together, today.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.greeting,
    required this.name,
    this.spouseName,
  });

  final String greeting;
  final String name;
  final String? spouseName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SakEnter(
          delay: const Duration(milliseconds: 120),
          child: Text(
            '$greeting,',
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        SakEnter(
          delay: const Duration(milliseconds: 260),
          slideFrom: 16,
          child: Text(
            name.isEmpty ? '' : '$name.',
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        if (spouseName != null && spouseName!.isNotEmpty) ...[
          const SizedBox(height: SakSpace.sm),
          SakEnter(
            delay: const Duration(milliseconds: 380),
            child: Text(
              'You and $spouseName, together.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GreetingSkeleton extends StatelessWidget {
  const _GreetingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SakShimmerBox(width: 180, height: 42, radius: SakRadius.sm),
        SizedBox(height: SakSpace.sm),
        SakShimmerBox(width: 240, height: 42, radius: SakRadius.sm),
        SizedBox(height: SakSpace.md),
        SakShimmerBox(width: 200, height: 16, radius: SakRadius.xs),
      ],
    );
  }
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({
    required this.next,
    required this.hasLocation,
    this.busy = false,
    this.onSetLocation,
  });

  final ScheduledPrayer? next;
  final bool hasLocation;
  final bool busy;
  final VoidCallback? onSetLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!hasLocation) {
      return SakCard(
        variant: SakCardVariant.tonal,
        onTap: busy ? null : onSetLocation,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(SakRadius.md),
              ),
              child: Icon(
                Icons.place_outlined,
                size: 20,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: SakSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set your location',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    busy
                        ? 'Getting your location…'
                        : 'So we can show your next prayer time.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.4),
              ),
          ],
        ),
      );
    }

    final label = nextPrayerLabel(next);
    final name = next?.prayer.displayName ?? '';

    return SakBreathing(
      child: Container(
        padding: const EdgeInsets.all(SakSpace.xl),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(SakRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next prayer',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onPrimary.withValues(alpha: 0.7),
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: SakSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedSwitcher(
                  duration: SakMotion.gentle,
                  switchInCurve: SakMotion.enter,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    name,
                    key: ValueKey(name),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: SakSpace.md),
                Expanded(
                  child: Text(
                    label.replaceFirst('$name ', ''),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.8),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: SakSpace.lg),
              AnimatedSwitcher(
                duration: SakMotion.slow,
                child: Text(
                  _arabicNameFor(name),
                  key: ValueKey('ar_$name'),
                  style: SakTypography.arabicText(
                    fontSize: 22,
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _arabicNameFor(String english) => switch (english.toLowerCase()) {
        'fajr' => 'ٱلْفَجْر',
        'dhuhr' => 'ٱلظُّهْر',
        'asr' => 'ٱلْعَصْر',
        'maghrib' => 'ٱلْمَغْرِب',
        'isha' => 'ٱلْعِشَاء',
        _ => '',
      };
}

class _CycleTile extends StatelessWidget {
  const _CycleTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SakCard(
      variant: SakCardVariant.tonal,
      onTap: () => context.go('/home/cycle'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(SakRadius.md),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: SakSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cycle', style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Track your cycle and see predictions.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _CareTile extends StatelessWidget {
  const _CareTile({required this.isWife});

  final bool isWife;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = isWife ? 'Caring for you' : 'Caring for her';
    return SakCard(
      variant: SakCardVariant.tonal,
      onTap: () => context.go('/home/care'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(SakRadius.md),
            ),
            child: Icon(
              Icons.spa_outlined,
              size: 20,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: SakSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Guidance and gentle tips.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }
}

class _NextPrayerSkeleton extends StatelessWidget {
  const _NextPrayerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SakSpace.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(SakRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SakShimmerBox(width: 100, height: 12, radius: SakRadius.xs),
          SizedBox(height: SakSpace.lg),
          SakShimmerBox(width: 200, height: 28, radius: SakRadius.sm),
          SizedBox(height: SakSpace.lg),
          SakShimmerBox(width: 80, height: 22, radius: SakRadius.xs),
        ],
      ),
    );
  }
}
