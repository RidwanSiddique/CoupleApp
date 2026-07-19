import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/storage/signal_db.dart';
import 'package:sakinah/features/chat/data/chat_store.dart';

void main() {
  late SignalDb db;
  late ChatStore store;
  setUp(() { db = SignalDb.memory(); store = ChatStore(db); });
  tearDown(() => db.close());

  test('upsert is idempotent by message id', () async {
    await store.upsertMessage(id: 'm1', senderId: 'a', body: 'hi',
        createdAt: DateTime(2026), status: 'delivered');
    await store.upsertMessage(id: 'm1', senderId: 'a', body: 'hi',
        createdAt: DateTime(2026), status: 'delivered');
    final rows = await store.watchConversation().first;
    expect(rows.length, 1);
  });

  test('applyReaction add then remove', () async {
    await store.upsertMessage(id: 'm1', senderId: 'a', body: 'hi',
        createdAt: DateTime(2026), status: 'sent');
    await store.applyReaction(messageId: 'm1', reactorId: 'b', emoji: '❤️', add: true);
    expect((await store.reactionsFor('m1')).length, 1);
    await store.applyReaction(messageId: 'm1', reactorId: 'b', emoji: '❤️', add: false);
    expect((await store.reactionsFor('m1')).length, 0);
  });

  test('watchConversation orders by createdAt', () async {
    await store.upsertMessage(id: 'm2', senderId: 'a', body: '2',
        createdAt: DateTime(2026, 1, 2), status: 'sent');
    await store.upsertMessage(id: 'm1', senderId: 'a', body: '1',
        createdAt: DateTime(2026, 1, 1), status: 'sent');
    final rows = await store.watchConversation().first;
    expect(rows.map((r) => r.id), ['m1', 'm2']);
  });
}
