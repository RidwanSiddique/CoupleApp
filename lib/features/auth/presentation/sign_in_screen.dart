import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/tokens.dart';
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
      // Ensure a Signal identity is provisioned for this device.
      await ref.read(signalBootstrapProvider).ensureBundle();
      // Router redirect will move us onward.
    } on AppFailure catch (e) {
      setState(() => _error = e.message);
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
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SakScaffold(
      padded: true,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Assalāmu ʿalaykum',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: SakSpace.sm),
              Text(
                _mode == _Mode.password
                    ? 'Sign in with your email and password.'
                    : 'We\'ll send a 6-digit code to your email.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: SakSpace.xxl),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _mode == _Mode.password
                    ? TextInputAction.next
                    : TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              if (_mode == _Mode.password) ...[
                const SizedBox(height: SakSpace.md),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  onSubmitted: (_) => _signInWithPassword(),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: SakSpace.md),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: SakSpace.xl),
              SakButton(
                label: _mode == _Mode.password
                    ? 'Sign in'
                    : 'Send verification code',
                onPressed: _mode == _Mode.password
                    ? _signInWithPassword
                    : _sendOtp,
                loading: _busy,
                expand: true,
              ),
              const SizedBox(height: SakSpace.md),
              SakButton(
                label: _mode == _Mode.password
                    ? 'Use email code instead'
                    : 'Use password instead',
                variant: SakButtonVariant.text,
                onPressed: () {
                  setState(() {
                    _mode = _mode == _Mode.password ? _Mode.otp : _Mode.password;
                    _error = null;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
