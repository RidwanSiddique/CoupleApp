import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/domain/auth_controller.dart';
import 'invite_tab.dart';
import 'join_tab.dart';

class PairScreen extends ConsumerWidget {
  const PairScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final email = ref
        .watch(authSessionProvider)
        .asData
        ?.value
        ?.user
        .email;

    return DefaultTabController(
      length: 2,
      child: SakScaffold(
        padded: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authRepositoryProvider).signOut();
              }
            },
            itemBuilder: (_) => [
              if (email != null)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    'Signed in as $email',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SakSpace.lg,
                SakSpace.xl,
                SakSpace.lg,
                SakSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create your space of two',
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: SakSpace.sm),
                  Text(
                    'Share a code with your spouse, or enter theirs. Only the two of you will be in this space.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Invite'),
                Tab(text: 'Join'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  InviteTab(),
                  JoinTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
