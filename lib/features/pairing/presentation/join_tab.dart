import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../domain/pairing_providers.dart';

class JoinTab extends ConsumerStatefulWidget {
  const JoinTab({super.key});

  @override
  ConsumerState<JoinTab> createState() => _JoinTabState();
}

class _JoinTabState extends ConsumerState<JoinTab> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-character code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(pairingRepositoryProvider).acceptInvite(code);
      // currentCoupleProvider stream will flip; router will redirect.
    } on AppFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(SakSpace.lg),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: SakSpace.xxl),
            Icon(
              Icons.qr_code_scanner_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: SakSpace.lg),
            Text(
              'Enter your spouse\'s code',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: SakSpace.xl),
            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
                UpperCaseTextFormatter(),
              ],
              style: theme.textTheme.displayMedium?.copyWith(letterSpacing: 4),
              decoration: const InputDecoration(hintText: 'ABC123'),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: SakSpace.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: SakSpace.xl),
            SakButton(
              label: 'Join',
              onPressed: _submit,
              loading: _busy,
              expand: true,
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
