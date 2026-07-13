import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../data/pairing_repository.dart';
import '../domain/pairing_providers.dart';

class InviteTab extends ConsumerStatefulWidget {
  const InviteTab({super.key});

  @override
  ConsumerState<InviteTab> createState() => _InviteTabState();
}

class _InviteTabState extends ConsumerState<InviteTab> {
  PairingInvite? _invite;
  String? _error;
  bool _loading = false;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invite =
          await ref.read(pairingRepositoryProvider).createInvite();
      _startTicker(invite.expiresAt);
      setState(() => _invite = invite);
    } on AppFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startTicker(DateTime expiresAt) {
    _ticker?.cancel();
    void tick() {
      final left = expiresAt.difference(DateTime.now());
      if (left.isNegative) {
        setState(() {
          _remaining = Duration.zero;
          _invite = null;
        });
        _ticker?.cancel();
        return;
      }
      setState(() => _remaining = left);
    }

    tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(SakSpace.lg),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (_invite == null) ...[
              const SizedBox(height: SakSpace.xxl),
              Icon(
                Icons.favorite_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: SakSpace.lg),
              Text(
                'Generate a one-time code',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: SakSpace.sm),
              Text(
                'Codes expire in 10 minutes and can only be used once.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: SakSpace.xl),
              SakButton(
                label: 'Generate code',
                onPressed: _generate,
                loading: _loading,
                expand: true,
              ),
            ] else ...[
              SakCard(
                child: Column(
                  children: [
                    Text(
                      _invite!.code,
                      style: theme.textTheme.displayLarge?.copyWith(
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: SakSpace.md),
                    Text(
                      'Expires in ${_fmt(_remaining)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: SakSpace.xl),
                    QrImageView(
                      data: 'sakinah://pair?code=${_invite!.code}',
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: SakSpace.md),
                    Text(
                      'Or share the code above with your spouse.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SakSpace.lg),
              SakButton(
                label: 'Cancel and generate a new one',
                variant: SakButtonVariant.text,
                onPressed: () {
                  _ticker?.cancel();
                  setState(() {
                    _invite = null;
                    _remaining = Duration.zero;
                  });
                },
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: SakSpace.lg),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
