import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../../core/motion/motion.dart';
import '../../../core/platform/haptics.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _slots = SakDigitSlotsController();
  bool _busy = false;
  String? _error;

  Future<void> _verify(String code) async {
    if (code.length != 6) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).verifyEmailOtp(
            email: widget.email,
            token: code,
          );
      await ref.read(signalBootstrapProvider).ensureBundle();
      unawaited(SakHaptics.medium());
    } on AppFailure catch (e) {
      _slots.shake();
      unawaited(SakHaptics.medium());
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      _slots.shake();
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SakScaffold(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SakEnter(
                  child: Text(
                    'Enter your code',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall,
                  ),
                ),
                const SizedBox(height: SakSpace.sm),
                SakEnter(
                  delay: const Duration(milliseconds: 60),
                  child: Text(
                    'Sent to ${widget.email}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: SakSpace.xxxl),
                SakDigitSlots(
                  length: 6,
                  mode: SakDigitMode.numeric,
                  controller: _slots,
                  onCompleted: _verify,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: SakSpace.lg),
                  SakInlineError(message: _error!),
                ],
                const SizedBox(height: SakSpace.xxl),
                if (_busy)
                  Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  )
                else
                  SakEnter(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Auto-verifies when you finish typing.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
