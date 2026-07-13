import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_controller.dart';
import '../../pairing/domain/pairing_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final couple = ref.watch(currentCoupleProvider);

    return SakScaffold(
      title: 'Sakīnah',
      showDualDate: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
      child: couple.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (c) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SakSpace.xl),
            SakCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re paired',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: SakSpace.sm),
                  Text(
                    c == null
                        ? 'No couple yet.'
                        : 'Couple ${c.id.substring(0, 8)}… — the deen, connection, and distance features arrive in the next phase.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Phase 1 features coming soon.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: SakSpace.xxl),
          ],
        ),
      ),
    );
  }
}
