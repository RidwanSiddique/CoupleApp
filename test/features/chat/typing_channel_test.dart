import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/chat/data/typing_channel.dart';

void main() {
  test('debouncer emits true once then false after the quiet window', () {
    fakeAsync((async) {
      final events = <bool>[];
      final d = TypingDebouncer(quiet: const Duration(seconds: 3), emit: events.add);
      d.onKeystroke();
      d.onKeystroke();
      expect(events, [true]); // only one true despite two keystrokes
      async.elapse(const Duration(seconds: 3));
      expect(events, [true, false]);
    });
  });
}
