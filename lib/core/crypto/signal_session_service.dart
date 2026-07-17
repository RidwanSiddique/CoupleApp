// lib/core/crypto/signal_session_service.dart
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../storage/signal_db.dart';
import 'key_vault.dart';
import 'prekey_bundle_source.dart';
import 'stores/drift_signal_store.dart';

/// One encrypted copy of a message, addressed to a single device.
class EncryptedCopy {
  const EncryptedCopy({
    required this.userId,
    required this.deviceNum,
    required this.ciphertext,
    required this.cipherType,
  });

  final String userId;
  final int deviceNum;
  final Uint8List ciphertext;

  /// [CiphertextMessage.prekeyType] (3) for the first message to a device,
  /// [CiphertextMessage.whisperType] (2) afterwards.
  final int cipherType;
}

/// The only crypto API the rest of the app uses. Nothing above this layer
/// should import libsignal.
class SignalSessionService {
  SignalSessionService({
    required SignalDb db,
    required KeyVault vault,
    required PreKeyBundleSource bundles,
    required String selfUserId,
    required int selfDeviceNum,
  })  : store = DriftSignalStore(db, vault),
        _bundles = bundles,
        _selfUserId = selfUserId,
        _selfDeviceNum = selfDeviceNum;

  /// Exposed so tests can seed this device's own prekeys.
  final DriftSignalStore store;
  final PreKeyBundleSource _bundles;
  final String _selfUserId;
  final int _selfDeviceNum;

  /// Encrypt one copy per recipient device, plus per this user's OTHER devices
  /// so sent messages appear there too.
  Future<List<EncryptedCopy>> encryptFor({
    required String recipientUserId,
    required Uint8List plaintext,
  }) async {
    final targets = <({String userId, int deviceNum})>[];

    if (recipientUserId != _selfUserId) {
      for (final b in await _bundles.bundlesFor(recipientUserId)) {
        targets.add((userId: recipientUserId, deviceNum: b.deviceNum));
      }
    }
    for (final b in await _bundles.bundlesFor(_selfUserId)) {
      if (b.deviceNum == _selfDeviceNum) continue;
      targets.add((userId: _selfUserId, deviceNum: b.deviceNum));
    }

    final copies = <EncryptedCopy>[];
    for (final t in targets) {
      final address = SignalProtocolAddress(t.userId, t.deviceNum);
      await _ensureSession(address);
      final cipher = SessionCipher.fromStore(store, address);
      final message = await cipher.encrypt(plaintext);
      copies.add(EncryptedCopy(
        userId: t.userId,
        deviceNum: t.deviceNum,
        ciphertext: Uint8List.fromList(message.serialize()),
        cipherType: message.getType(),
      ));
    }
    return copies;
  }

  Future<Uint8List> decryptFrom({
    required String senderUserId,
    required int senderDeviceNum,
    required Uint8List ciphertext,
    required int cipherType,
  }) async {
    final address = SignalProtocolAddress(senderUserId, senderDeviceNum);
    final cipher = SessionCipher.fromStore(store, address);

    if (cipherType == CiphertextMessage.prekeyType) {
      // X3DH: processing this establishes the session on our side.
      return cipher.decrypt(PreKeySignalMessage(ciphertext));
    }
    return cipher.decryptFromSignal(SignalMessage.fromSerialized(ciphertext));
  }

  /// X3DH only when we have no session for this address yet.
  Future<void> _ensureSession(SignalProtocolAddress address) async {
    if (await store.containsSession(address)) return;

    final bundles = await _bundles.bundlesFor(address.getName());
    final match = bundles
        .where((b) => b.deviceNum == address.getDeviceId())
        .toList();
    if (match.isEmpty) {
      throw StateError(
          'No published bundle for ${address.getName()}:${address.getDeviceId()}');
    }
    final builder = SessionBuilder.fromSignalStore(store, address);
    await builder.processPreKeyBundle(match.first.toPreKeyBundle());
  }
}
