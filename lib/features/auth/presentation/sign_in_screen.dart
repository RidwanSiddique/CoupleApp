import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/errors/failures.dart';
import '../../../core/motion/motion.dart';
import '../../../core/platform/haptics.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/auth_controller.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

enum _Mode { password, otp }

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;
  _Mode _mode = _Mode.password;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithPassword(
            email: email,
            password: password,
          );
      await ref.read(signalBootstrapProvider).ensureBundle();
      unawaited(SakHaptics.medium());
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(email);
      if (!mounted) return;
      context.push('/auth/otp?email=${Uri.encodeComponent(email)}');
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SakScaffold(
      showAppBar: false,
      padded: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Salām — glyph-stagger reveal.
                Center(
                  child: _GlyphStagger(
                    text: 'ٱلسَّلَامُ عَلَيْكُمْ',
                    style: SakTypography.arabicText(
                      fontSize: 34,
                      color: theme.colorScheme.primary,
                    ),
                    perGlyph: const Duration(milliseconds: 40),
                  ),
                ),
                const SizedBox(height: SakSpace.xs),

                // Wordmark hero — flies from splash.
                Hero(
                  tag: 'sakinah-mark',
                  flightShuttleBuilder: (_, _, _, _, _) => Material(
                    type: MaterialType.transparency,
                    child: Text(
                      'سَكِينَة',
                      textAlign: TextAlign.center,
                      style: SakTypography.arabicText(
                        fontSize: 34,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      'Sakīnah',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayMedium?.copyWith(
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: SakSpace.sm),
                SakEnter(
                  delay: const Duration(milliseconds: 420),
                  child: Text(
                    'A private space, for the two of you.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: SakSpace.xxxl),

                SakEnter(
                  delay: const Duration(milliseconds: 520),
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: _mode == _Mode.password
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline, size: 20),
                    ),
                  ),
                ),
                if (_mode == _Mode.password) ...[
                  const SizedBox(height: SakSpace.md),
                  SakEnter(
                    delay: const Duration(milliseconds: 580),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline, size: 20),
                      ),
                      onSubmitted: (_) => _signInWithPassword(),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: SakSpace.md),
                  SakInlineError(message: _error!),
                ],
                const SizedBox(height: SakSpace.xl),
                SakEnter(
                  delay: const Duration(milliseconds: 640),
                  child: SakButton(
                    label: _mode == _Mode.password
                        ? 'Sign in'
                        : 'Send verification code',
                    onPressed: _busy
                        ? null
                        : (_mode == _Mode.password
                            ? _signInWithPassword
                            : _sendOtp),
                    loading: _busy,
                    expand: true,
                  ),
                ),
                const SizedBox(height: SakSpace.md),
                SakEnter(
                  delay: const Duration(milliseconds: 720),
                  child: SakButton(
                    label: _mode == _Mode.password
                        ? 'Use a one-time code instead'
                        : 'Use password instead',
                    variant: SakButtonVariant.text,
                    size: SakButtonSize.small,
                    onPressed: () {
                      setState(() {
                        _mode = _mode == _Mode.password
                            ? _Mode.otp
                            : _Mode.password;
                        _error = null;
                      });
                    },
                  ),
                ),
                if (_mode == _Mode.password)
                  SakEnter(
                    delay: const Duration(milliseconds: 760),
                    child: SakButton(
                      label: 'Forgot password?',
                      variant: SakButtonVariant.text,
                      size: SakButtonSize.small,
                      onPressed: () => context.push('/auth/forgot-password'),
                    ),
                  ),
                const SizedBox(height: SakSpace.lg),
                SakEnter(
                  delay: const Duration(milliseconds: 800),
                  child: SakButton(
                    label: 'Create an account',
                    variant: SakButtonVariant.text,
                    size: SakButtonSize.small,
                    onPressed: () => context.push('/auth/sign-up'),
                  ),
                ),
                const SizedBox(height: SakSpace.lg),
                SakEnter(
                  delay: const Duration(milliseconds: 840),
                  child: Text(
                    _mode == _Mode.otp
                        ? "We'll email you a ${Env.otpLength}-digit code. No password needed."
                        : "Signing in creates your secure keys for chat.",
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

/// Renders a string glyph-by-glyph, each glyph fading + rising into place
/// with an incremental delay.
class _GlyphStagger extends StatelessWidget {
  const _GlyphStagger({
    required this.text,
    required this.style,
    this.perGlyph = const Duration(milliseconds: 40),
  });

  final String text;
  final TextStyle style;
  final Duration perGlyph;
  static const Duration _initialDelay = Duration(milliseconds: 80);

  @override
  Widget build(BuildContext context) {
    // Split by grapheme clusters so we don't break combining marks.
    final chars = text.characters.toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < chars.length; i++)
            SakEnter(
              delay: _initialDelay + perGlyph * i,
              duration: SakMotion.gentle,
              slideFrom: 6,
              child: Text(chars[i], style: style),
            ),
        ],
      ),
    );
  }
}
