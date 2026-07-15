import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/motion/motion.dart';
import '../../../core/platform/haptics.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/time/prayer_engine.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_controller.dart';
import '../../home/domain/home_providers.dart';
import '../../pairing/domain/pairing_providers.dart';
import '../domain/prayer_log_providers.dart';
import '../../../shared/models/prayer_log.dart';

class PrayerLogScreen extends ConsumerWidget {
  const PrayerLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedDate = ref.watch(prayerLogSelectedDateProvider);
    final summary = ref.watch(prayerDaySummaryProvider);
    final ownProfile = ref.watch(ownProfileProvider).asData?.value;
    final spouseProfile = ref.watch(spouseProfileProvider).asData?.value;
    final logsAsync = ref.watch(prayerLogsForDayProvider);

    final today = DateTime.now();
    final isToday = _sameDay(selectedDate, today);

    return SakScaffold(
      title: 'Prayer log',
      subtitle: Text(
        isToday
            ? DateFormat('EEEE, d MMMM').format(selectedDate)
            : DateFormat('EEEE, d MMM y').format(selectedDate),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(prayerLogSelectedDateProvider.notifier).set(
              selectedDate.subtract(const Duration(days: 1)),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isToday
              ? null
              : () {
                  ref.read(prayerLogSelectedDateProvider.notifier).set(
                    selectedDate.add(const Duration(days: 1)),
                  );
                },
        ),
      ],
      child: logsAsync.when(
        loading: () => const _LogSkeleton(),
        error: (e, _) => Center(
          child: Text('Could not load prayer log',
              style: theme.textTheme.bodyMedium),
        ),
        data: (logs) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: SakSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SakEnter(
                child: _TogetherStrip(
                  ownCount: summary.ownCount,
                  spouseCount: summary.spouseCount,
                  togetherWindowSeconds: summary.togetherWindowSeconds,
                  ownName: ownProfile?.displayName ?? 'You',
                  spouseName: spouseProfile?.displayName ?? 'Your spouse',
                ),
              ),
              const SizedBox(height: SakSpace.xl),
              SakStagger(
                initialDelay: const Duration(milliseconds: 80),
                stagger: const Duration(milliseconds: 50),
                children: [
                  for (final p in Prayer.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: SakSpace.md),
                      child: _PrayerRow(
                        prayer: p,
                        isEditable: isToday || selectedDate.isBefore(today),
                        ownLog: _findLog(logs, ownProfile?.id, p),
                        spouseLog: _findLog(logs, spouseProfile?.id, p),
                        onOwnToggle: (newStatus) async {
                          await _toggleOwn(
                            ref: ref,
                            prayer: p,
                            date: selectedDate,
                            newStatus: newStatus,
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: SakSpace.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  PrayerLogEntry? _findLog(
    List<PrayerLogEntry> logs,
    String? userId,
    Prayer p,
  ) {
    if (userId == null) return null;
    for (final l in logs) {
      if (l.userId == userId && l.prayer == p) return l;
    }
    return null;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _toggleOwn({
    required WidgetRef ref,
    required Prayer prayer,
    required DateTime date,
    required PrayerStatus? newStatus,
  }) async {
    final couple = ref.read(currentCoupleProvider).asData?.value;
    final session = ref.read(authSessionProvider).asData?.value;
    if (couple == null || session == null) return;
    final repo = ref.read(prayerLogRepositoryProvider);
    // Distinct haptic per direction: heavier for a log, light for an unlog.
    if (newStatus == null) {
      unawaited(SakHaptics.light());
    } else {
      unawaited(SakHaptics.medium());
    }
    if (newStatus == null) {
      await repo.unlogPrayer(
        coupleId: couple.id,
        userId: session.user.id,
        date: date,
        prayer: prayer,
      );
    } else {
      await repo.logPrayer(
        coupleId: couple.id,
        userId: session.user.id,
        date: date,
        prayer: prayer,
        status: newStatus,
      );
    }
  }
}

class _TogetherStrip extends StatelessWidget {
  const _TogetherStrip({
    required this.ownCount,
    required this.spouseCount,
    required this.togetherWindowSeconds,
    required this.ownName,
    required this.spouseName,
  });

  final int ownCount;
  final int spouseCount;
  final int? togetherWindowSeconds;
  final String ownName;
  final String spouseName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final togetherOK = togetherWindowSeconds != null;

    return Container(
      padding: const EdgeInsets.all(SakSpace.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(SakRadius.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ownName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondary
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                SakDigitRow(
                  value: ownCount,
                  minDigits: 1,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            togetherOK ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            color: theme.colorScheme.onSecondary,
            size: 20,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  spouseName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondary
                        .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                SakDigitRow(
                  value: spouseCount,
                  minDigits: 1,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.ownLog,
    required this.spouseLog,
    required this.isEditable,
    required this.onOwnToggle,
  });

  final Prayer prayer;
  final PrayerLogEntry? ownLog;
  final PrayerLogEntry? spouseLog;
  final bool isEditable;
  final ValueChanged<PrayerStatus?> onOwnToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ownDone = ownLog?.status == PrayerStatus.prayed;
    final spouseDone = spouseLog?.status == PrayerStatus.prayed;

    return SakCard(
      variant: SakCardVariant.plain,
      padding: const EdgeInsets.symmetric(
        horizontal: SakSpace.lg,
        vertical: SakSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      prayer.displayName,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(width: SakSpace.sm),
                    Text(
                      _arabicName(prayer),
                      style: SakTypography.arabicText(
                        fontSize: 18,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _footerLabel(ownLog, spouseLog),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (spouseDone)
            Container(
              margin: const EdgeInsets.only(right: SakSpace.sm),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
          _CheckToggle(
            checked: ownDone,
            enabled: isEditable,
            onChanged: () =>
                onOwnToggle(ownDone ? null : PrayerStatus.prayed),
          ),
        ],
      ),
    );
  }

  String _arabicName(Prayer p) => switch (p) {
        Prayer.fajr => 'ٱلْفَجْر',
        Prayer.dhuhr => 'ٱلظُّهْر',
        Prayer.asr => 'ٱلْعَصْر',
        Prayer.maghrib => 'ٱلْمَغْرِب',
        Prayer.isha => 'ٱلْعِشَاء',
      };

  String _footerLabel(PrayerLogEntry? own, PrayerLogEntry? spouse) {
    if (own == null && spouse == null) return 'Not yet';
    if (own?.status == PrayerStatus.prayed &&
        spouse?.status == PrayerStatus.prayed) {
      return 'Both prayed';
    }
    if (own?.status == PrayerStatus.prayed) return "You've prayed";
    if (spouse?.status == PrayerStatus.prayed) return 'Your spouse prayed';
    return 'Not yet';
  }
}

class _CheckToggle extends StatefulWidget {
  const _CheckToggle({
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  final bool checked;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  State<_CheckToggle> createState() => _CheckToggleState();
}

class _CheckToggleState extends State<_CheckToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant _CheckToggle old) {
    super.didUpdateWidget(old);
    if (old.checked != widget.checked) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GestureDetector(
      onTapDown:
          widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel:
          widget.enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onChanged();
            }
          : null,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = _pulse.value;
          // Spring-out overshoot: quickly to 1.18 then settle to 1.0.
          final bounce = t == 0
              ? 1.0
              : 1.0 +
                  0.18 *
                      (1 - t) *
                      (t < 0.4
                          ? (t / 0.4)
                          : 1 - ((t - 0.4) / 0.6) * 0.6);
          final pressScale = _pressed && widget.enabled ? 0.92 : 1.0;
          return Transform.scale(scale: bounce * pressScale, child: child);
        },
        child: AnimatedContainer(
          duration: SakMotion.standard,
          curve: SakMotion.enter,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.checked
                ? scheme.primary
                : scheme.surfaceContainerLow,
            shape: BoxShape.circle,
            border: widget.checked
                ? null
                : Border.all(color: scheme.outlineVariant, width: 1.5),
            boxShadow: widget.checked
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: SakMotion.standard,
            switchInCurve: SakMotion.springOut,
            switchOutCurve: SakMotion.enter,
            transitionBuilder: (c, a) => ScaleTransition(
              scale: Tween<double>(begin: 0.4, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: c),
            ),
            child: widget.checked
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('checked'),
                    size: 24,
                    color: scheme.onPrimary,
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ),
    );
  }
}

class _LogSkeleton extends StatelessWidget {
  const _LogSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: SakSpace.lg),
      child: Column(
        children: [
          SakShimmerBox(height: 88, radius: SakRadius.lg),
          SizedBox(height: SakSpace.lg),
          SakShimmerBox(height: 72, radius: SakRadius.lg),
          SizedBox(height: SakSpace.md),
          SakShimmerBox(height: 72, radius: SakRadius.lg),
          SizedBox(height: SakSpace.md),
          SakShimmerBox(height: 72, radius: SakRadius.lg),
          SizedBox(height: SakSpace.md),
          SakShimmerBox(height: 72, radius: SakRadius.lg),
          SizedBox(height: SakSpace.md),
          SakShimmerBox(height: 72, radius: SakRadius.lg),
        ],
      ),
    );
  }
}
