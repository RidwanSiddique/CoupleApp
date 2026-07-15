import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/motion/motion.dart';
import '../../../core/platform/haptics.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_controller.dart';
import '../../pairing/domain/pairing_providers.dart';
import '../data/gratitude_repository.dart';
import '../domain/gratitude_providers.dart';

class GratitudeScreen extends ConsumerStatefulWidget {
  const GratitudeScreen({super.key});

  @override
  ConsumerState<GratitudeScreen> createState() => _GratitudeScreenState();
}

class _GratitudeScreenState extends ConsumerState<GratitudeScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;
  bool _revealNow = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final couple = ref.read(currentCoupleProvider).asData?.value;
    final session = ref.read(authSessionProvider).asData?.value;
    if (couple == null || session == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(gratitudeRepositoryProvider).add(
            coupleId: couple.id,
            userId: session.user.id,
            body: text,
            revealToSpouse: _revealNow,
          );
      unawaited(SakHaptics.medium());
      _controller.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notesAsync = ref.watch(gratitudeNotesProvider);
    final session = ref.watch(authSessionProvider).asData?.value;
    final myId = session?.user.id;

    return SakScaffold(
      title: 'Jar of good memories',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      child: notesAsync.when(
        loading: () => const Center(
          child: SakShimmerBox(height: 200, radius: SakRadius.lg),
        ),
        error: (e, _) => Center(
          child: Text('Could not load', style: theme.textTheme.bodyMedium),
        ),
        data: (notes) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: SakSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SakEnter(
                child: SakCard(
                  variant: SakCardVariant.tonal,
                  padding: const EdgeInsets.all(SakSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'One thing you appreciated today',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: SakSpace.md),
                      TextField(
                        controller: _controller,
                        maxLines: 5,
                        minLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Small things count.',
                        ),
                      ),
                      const SizedBox(height: SakSpace.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _revealNow
                                  ? 'Reveal to your spouse now.'
                                  : 'Keep private for now.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Switch.adaptive(
                            value: _revealNow,
                            onChanged: (v) {
                              setState(() => _revealNow = v);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: SakSpace.sm),
                      SakButton(
                        label: 'Drop in the jar',
                        icon: Icons.favorite_outline_rounded,
                        onPressed: _submitting ? null : _submit,
                        loading: _submitting,
                        expand: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: SakSpace.xl),
              if (notes.isEmpty)
                SakEnter(
                  delay: const Duration(milliseconds: 100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: SakSpace.xxl),
                    child: Center(
                      child: Text(
                        'The jar is empty for now. Fill it together.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              else
                SakStagger(
                  initialDelay: const Duration(milliseconds: 100),
                  stagger: const Duration(milliseconds: 40),
                  children: [
                    for (final n in notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: SakSpace.md),
                        child: _NoteTile(
                          note: n,
                          isOwn: n.authorId == myId,
                          onReveal: n.authorId == myId && !n.revealToSpouse
                              ? () => ref
                                  .read(gratitudeRepositoryProvider)
                                  .reveal(n.id)
                              : null,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: SakSpace.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.isOwn, this.onReveal});
  final GratitudeNote note;
  final bool isOwn;
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hidden = !isOwn && !note.revealToSpouse;
    return SakCard(
      variant: SakCardVariant.plain,
      padding: const EdgeInsets.all(SakSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isOwn
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: SakSpace.sm),
              Text(
                isOwn ? 'From you' : 'From your spouse',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat.MMMd().format(note.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: SakSpace.sm),
          hidden
              ? Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: SakSpace.xs),
                    Text(
                      'Kept for now.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                )
              : Text(
                  note.body,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
          if (onReveal != null && !note.revealToSpouse) ...[
            const SizedBox(height: SakSpace.sm),
            Align(
              alignment: Alignment.centerRight,
              child: SakButton(
                label: 'Reveal to your spouse',
                variant: SakButtonVariant.text,
                size: SakButtonSize.small,
                onPressed: onReveal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
