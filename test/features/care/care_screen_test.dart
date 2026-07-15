// test/features/care/care_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakinah/shared/models/care_tip.dart';
import 'package:sakinah/features/care/domain/care_providers.dart';
import 'package:sakinah/features/care/presentation/care_screen.dart';

void main() {
  testWidgets('shows a tip, its pending-review note, and medical disclaimer',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        careTipsProvider.overrideWith((ref) async => const [
          CareTip(audience: 'wife', category: 'spiritual', title: 'Close to Allah',
              body: 'Body', reviewStatus: 'pending_review',
              islamicReference: 'Q 2:185'),
        ]),
      ],
      child: const MaterialApp(home: CareScreen()),
    ));
    await tester.pump();
    expect(find.text('Close to Allah'), findsOneWidget);
    expect(find.textContaining('verify'), findsWidgets); // pending-review note
    expect(find.textContaining('not medical advice'), findsOneWidget);
  });
}
