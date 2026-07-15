// test/features/settings/settings_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakinah/features/cycle/domain/cycle_providers.dart';
import 'package:sakinah/features/settings/domain/settings_providers.dart';
import 'package:sakinah/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('wife sees the cycle privacy toggle', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        isWifeProvider.overrideWithValue(true),
        preferencesProvider.overrideWith((ref) async => <String, dynamic>{}),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pump();
    expect(find.textContaining('Share cycle'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsWidgets);
  });

  testWidgets('husband does not see the cycle privacy toggle', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        isWifeProvider.overrideWithValue(false),
        preferencesProvider.overrideWith((ref) async => <String, dynamic>{}),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pump();
    expect(find.textContaining('Share cycle'), findsNothing);
  });
}
