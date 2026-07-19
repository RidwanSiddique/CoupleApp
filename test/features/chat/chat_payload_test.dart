import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/chat/domain/chat_payload.dart';

void main() {
  test('text round-trips, including reply', () {
    for (final p in [
      const TextPayload(body: 'salam'),
      const TextPayload(body: 're', replyToMessageId: 'm1'),
    ]) {
      final decoded = decodePayload(encodePayload(p));
      expect(decoded, isA<TextPayload>());
      final t = decoded as TextPayload;
      expect(t.body, p.body);
      expect(t.replyToMessageId, p.replyToMessageId);
    }
  });

  test('reaction round-trips add and remove', () {
    for (final add in [true, false]) {
      final p = ReactionPayload(targetMessageId: 'm9', emoji: '❤️', add: add);
      final decoded = decodePayload(encodePayload(p)) as ReactionPayload;
      expect(decoded.targetMessageId, 'm9');
      expect(decoded.emoji, '❤️');
      expect(decoded.add, add);
    }
  });

  test('unknown kind or newer version decodes to UnsupportedPayload', () {
    final future = '{"v":99,"kind":"hologram"}';
    final bytes = Uint8ListFromString(future);
    expect(decodePayload(bytes), isA<UnsupportedPayload>());
  });
}

Uint8List Uint8ListFromString(String s) => Uint8List.fromList(utf8.encode(s));
