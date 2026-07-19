// lib/features/chat/domain/chat_service.dart
import 'dart:typed_data';
import '../../../core/crypto/signal_session_service.dart';
import '../data/chat_repository.dart';
import '../data/chat_store.dart';
import 'chat_payload.dart';

class ChatService {
  ChatService({
    required this.session,
    required this.repo,
    required this.store,
    required this.selfUserId,
    required this.spouseUserId,
    required this.selfDeviceNum,
  });

  final SignalSessionService session;
  final ChatRepository repo;
  final ChatStore store;
  final String selfUserId;
  final String spouseUserId;
  final int selfDeviceNum;

  Future<void> sendText(String body, {String? replyToMessageId}) async {
    final payload = TextPayload(body: body, replyToMessageId: replyToMessageId);
    final copies = await session.encryptFor(
      recipientUserId: spouseUserId,
      plaintext: encodePayload(payload),
    );
    final sent = await repo.sendEnvelopes(
        senderDeviceNum: selfDeviceNum, copies: copies);
    await store.upsertMessage(
      id: sent.messageId,
      senderId: selfUserId,
      body: body,
      replyToMessageId: replyToMessageId,
      createdAt: sent.createdAt,
      status: 'sent',
    );
  }

  Future<void> sendReaction({
    required String targetMessageId,
    required String emoji,
    required bool add,
  }) async {
    final payload = ReactionPayload(
        targetMessageId: targetMessageId, emoji: emoji, add: add);
    final copies = await session.encryptFor(
      recipientUserId: spouseUserId,
      plaintext: encodePayload(payload),
    );
    await repo.sendEnvelopes(senderDeviceNum: selfDeviceNum, copies: copies);
    // Reflect our own reaction locally immediately.
    await store.applyReaction(
        messageId: targetMessageId, reactorId: selfUserId, emoji: emoji, add: add);
  }

  /// Decrypt one inbound envelope, apply it, acknowledge, and delete it.
  /// Never throws for a bad envelope — logs via return.
  Future<void> handleInboxRow(Map<String, dynamic> env) async {
    final messageId = env['message_id'] as String;
    if (await store.messageExists(messageId) && env['id'] != null) {
      // Already processed this logical message; just clean up the envelope.
      await repo.deleteEnvelope(env['id'] as String);
      return;
    }
    // Sender address comes from the envelope itself (denormalized): it may be
    // the spouse OR the recipient's own other device (multi-device sync).
    final String senderId = env['sender_id'] as String;
    final int senderDeviceNum = (env['sender_device_num'] as num).toInt();
    final Uint8List ciphertext = _bytes(env['ciphertext']);
    late final ChatPayload payload;
    try {
      final plain = await session.decryptFrom(
        senderUserId: senderId,
        senderDeviceNum: senderDeviceNum,
        ciphertext: ciphertext,
        cipherType: (env['cipher_type'] as num).toInt(),
      );
      payload = decodePayload(Uint8List.fromList(plain));
    } catch (_) {
      return; // leave fetched_at null; retried next tick
    }

    switch (payload) {
      case TextPayload():
        await store.upsertMessage(
          id: messageId,
          senderId: senderId,
          body: payload.body,
          replyToMessageId: payload.replyToMessageId,
          createdAt: DateTime.parse(env['created_at'] as String),
          // Own-device sync copies are already-sent; spouse copies are delivered.
          status: senderId == selfUserId ? 'sent' : 'delivered',
        );
        if (senderId != selfUserId) await repo.markDelivered(messageId);
      case ReactionPayload():
        await store.applyReaction(
          messageId: payload.targetMessageId,
          reactorId: senderId,
          emoji: payload.emoji,
          add: payload.add,
        );
      case UnsupportedPayload():
        break; // skip, still delete the envelope below
    }
    await repo.deleteEnvelope(env['id'] as String);
  }
}

Uint8List _bytes(dynamic v) {
  if (v is String) {
    final hex = v.startsWith('\\x') ? v.substring(2) : v;
    return Uint8List.fromList([
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16)
    ]);
  }
  return Uint8List.fromList((v as List).cast<int>());
}
