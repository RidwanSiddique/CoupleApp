// lib/features/chat/domain/chat_service.dart
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
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
    final id = const Uuid().v4();
    final now = DateTime.now();
    // The whole body — including the optimistic write — is covered here so
    // sendText never throws. It's invoked via unawaited(...) from _send, so
    // an escaping exception would become an unhandled async error.
    try {
      // Optimistic row shown immediately, before the network round-trip.
      await store.upsertMessage(
        id: id,
        senderId: selfUserId,
        body: body,
        replyToMessageId: replyToMessageId,
        createdAt: now,
        status: 'sending',
      );
      final payload = TextPayload(body: body, replyToMessageId: replyToMessageId);
      final copies = await session.encryptFor(
        recipientUserId: spouseUserId,
        plaintext: encodePayload(payload),
      );
      // The client-generated id is passed through as p_message_id so the
      // server message shares this same id — required for receipts to land
      // on this row instead of a different server-generated one.
      await repo.sendEnvelopes(
          senderDeviceNum: selfDeviceNum, copies: copies, messageId: id);
      await store.setStatus(id, 'sent');
    } catch (_) {
      try {
        await store.setStatus(id, 'failed');
      } catch (_) {
        // The optimistic write itself may have failed, so there's no row to
        // mark 'failed' against. Nothing more we can do here.
      }
    }
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
    // Only handle envelopes addressed to THIS device. A user's other devices
    // share the same recipient_id and appear in this stream, but their
    // envelopes are theirs to fetch — we must not read or delete them.
    final recipientDeviceNum = (env['recipient_device_num'] as num?)?.toInt();
    if (recipientDeviceNum != selfDeviceNum) return;

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
