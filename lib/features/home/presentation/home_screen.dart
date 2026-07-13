import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/time/prayer_engine.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_controller.dart';
import '../../pairing/domain/pairing_providers.dart';
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
            // Header: date + crescent + overflow menu
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
                      Expanded(
                        child: HijriDate(date: now),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz),
                        onSelected: (v) {
                          if (v == 'logout') {
                            ref.read(authRepositoryProvider).signOut();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_outlined, size: 18),
                                SizedBox(width: SakSpace.sm),
                                Text('Sign out'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Greeting
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

            const SliverPadding(
              padding: EdgeInsets.only(top: SakSpace.xxl),
              sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
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
                          hasLocation: own.asData?.value?.latitude != null &&
                              own.asData?.value?.longitude != null,
                        )
                      : const _NextPrayerSkeleton(),
                ),
              ),
            ),

            // Coming-next section
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: SakSpace.lg),
              sliver: SliverToBoxAdapter(
                child: SakEnter(
                  delay: const Duration(milliseconds: 460),
                  child: SakSectionHeader(
                    title: 'Today, together',
                    subtitle:
                        'Coming next: shared prayer log, dua list, and a daily prompt.',
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: SakSpace.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SakStagger(
                    initialDelay: const Duration(milliseconds: 540),
                    stagger: const Duration(milliseconds: 70),
                    children: const [
                      _ComingSoonTile(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Shared prayer log',
                        hint:
                            "Check in for each ṣalāh. See your spouse's too.",
                      ),
                      SizedBox(height: SakSpace.md),
                      _ComingSoonTile(
                        icon: Icons.menu_book_outlined,
                        title: 'Verse of the day',
                        hint: 'A curated verse for spouses, every morning.',
                      ),
                      SizedBox(height: SakSpace.md),
                      _ComingSoonTile(
                        icon: Icons.forum_outlined,
                        title: 'Private chat',
                        hint:
                            'End-to-end encrypted messages and voice notes.',
                      ),
                      SizedBox(height: SakSpace.md),
                      _ComingSoonTile(
                        icon: Icons.favorite_outline_rounded,
                        title: 'Gratitude for your spouse',
                        hint: 'One thing you appreciated today.',
                      ),
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
                          : 'You are paired.',
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

/// Greeting reveal: first line "$greeting," then the name after a delay.
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
  const _NextPrayerCard({required this.next, required this.hasLocation});

  final ScheduledPrayer? next;
  final bool hasLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!hasLocation) {
      return SakCard(
        variant: SakCardVariant.tonal,
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
                    'So we can show your next prayer time.',
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

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SakCard(
      variant: SakCardVariant.tonal,
      padding: const EdgeInsets.all(SakSpace.lg),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(SakRadius.md),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: SakSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SakSpace.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(SakRadius.sm),
            ),
            child: Text(
              'Soon',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
