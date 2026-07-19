// test/features/chat/chat_providers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakinah/core/crypto/crypto_providers.dart';
import 'package:sakinah/core/storage/signal_db.dart';
import 'package:sakinah/features/chat/data/chat_store.dart';
import 'package:sakinah/features/chat/domain/chat_providers.dart';

void main() {
  test('chatStoreProvider builds over the shared SignalDb', () {
    final c = ProviderContainer(overrides: [
      signalDbProvider.overrideWith((ref) {
        final db = SignalDb.memory();
        ref.onDispose(db.close);
        return db;
      }),
    ]);
    addTearDown(c.dispose);
    expect(c.read(chatStoreProvider), isA<ChatStore>());
  });
}
