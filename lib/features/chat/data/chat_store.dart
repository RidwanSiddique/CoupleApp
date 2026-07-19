import 'package:drift/drift.dart';
import '../../../core/storage/signal_db.dart';

typedef ChatMessageRow = ChatMessage;

class ChatStore {
  ChatStore(this._db);
  final SignalDb _db;

  Future<void> upsertMessage({
    required String id,
    required String senderId,
    required String? body,
    required DateTime createdAt,
    required String status,
    String? replyToMessageId,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return _db.into(_db.chatMessages).insertOnConflictUpdate(
          ChatMessagesCompanion.insert(
            id: id,
            senderId: senderId,
            body: Value(body),
            replyToMessageId: Value(replyToMessageId),
            createdAt: createdAt,
            deliveredAt: Value(deliveredAt),
            readAt: Value(readAt),
            status: status,
          ),
        );
  }

  Future<void> setStatus(String id, String status) {
    return (_db.update(_db.chatMessages)..where((t) => t.id.equals(id)))
        .write(ChatMessagesCompanion(status: Value(status)));
  }

  Future<void> applyReceipt({
    required String id,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) async {
    final status = readAt != null
        ? 'read'
        : (deliveredAt != null ? 'delivered' : null);
    await (_db.update(_db.chatMessages)..where((t) => t.id.equals(id))).write(
      ChatMessagesCompanion(
        deliveredAt: deliveredAt != null ? Value(deliveredAt) : const Value.absent(),
        readAt: readAt != null ? Value(readAt) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
      ),
    );
  }

  Future<bool> messageExists(String id) async {
    final row = await (_db.select(_db.chatMessages)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> applyReaction({
    required String messageId,
    required String reactorId,
    required String emoji,
    required bool add,
  }) async {
    if (add) {
      await _db.into(_db.chatReactions).insertOnConflictUpdate(
            ChatReactionsCompanion.insert(
              messageId: messageId,
              reactorId: reactorId,
              emoji: emoji,
              createdAt: DateTime.now(),
            ),
          );
    } else {
      await (_db.delete(_db.chatReactions)
            ..where((t) =>
                t.messageId.equals(messageId) &
                t.reactorId.equals(reactorId) &
                t.emoji.equals(emoji)))
          .go();
    }
  }

  Future<List<ChatReaction>> reactionsFor(String messageId) {
    return (_db.select(_db.chatReactions)
          ..where((t) => t.messageId.equals(messageId)))
        .get();
  }

  Stream<List<ChatMessageRow>> watchConversation() {
    return (_db.select(_db.chatMessages)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }
}
