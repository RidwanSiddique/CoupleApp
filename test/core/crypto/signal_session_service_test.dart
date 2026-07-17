// test/core/crypto/signal_session_service_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:sakinah/core/crypto/key_vault.dart';
import 'package:sakinah/core/crypto/prekey_bundle_source.dart';
import 'package:sakinah/core/crypto/secure_store.dart';
import 'package:sakinah/core/crypto/signal_keys.dart';
import 'package:sakinah/core/crypto/signal_session_service.dart';
import 'package:sakinah/core/crypto/stores/drift_signal_store.dart';
import 'package:sakinah/core/storage/signal_db.dart';

/// One simulated device: its own DB, vault and published bundle.
class _Device {
  _Device(this.userId, this.deviceNum);
  final String userId;
  final int deviceNum;
  late SignalDb db;
  late KeyVault vault;
  late GeneratedKeyBundle generated;
  late SignalSessionService service;
}

class _FakeBundles implements PreKeyBundleSource {
  _FakeBundles(this.devices);
  final List<_Device> devices;

  @override
  Future<List<DeviceBundle>> bundlesFor(String userId) async {
    return devices.where((d) => d.userId == userId).map((d) {
      final p = d.generated.public;
      final otp = p.oneTimePrekeys.first;
      return DeviceBundle(
        deviceNum: d.deviceNum,
        registrationId: p.registrationId,
        identityPub: p.identityPub,
        signedPrekeyId: p.signedPrekeyId,
        signedPrekeyPub: p.signedPrekeyPub,
        signedPrekeySig: p.signedPrekeySig,
        oneTimePrekeyId: otp.id,
        oneTimePrekeyPub: otp.pub,
      );
    }).toList();
  }
}

/// Builds a fully independent device: its own in-memory DB and its own isolated
/// vault, with its identity and prekeys already loaded. Devices never share
/// state, so any number can be active at once.
Future<_Device> _makeDevice(String userId, int deviceNum,
    List<_Device> registry) async {
  final d = _Device(userId, deviceNum);
  d.db = SignalDb.memory();
  d.vault = KeyVault(InMemorySecureStore());
  d.generated = generateBundle(deviceId: '$userId-$deviceNum');
  await d.vault.savePrivate(d.generated.private);
  await d.vault.saveDeviceNum(deviceNum);
  d.service = SignalSessionService(
    db: d.db,
    vault: d.vault,
    bundles: _FakeBundles(registry),
    selfUserId: userId,
    selfDeviceNum: deviceNum,
  );
  // Its own prekeys must be in its store so incoming prekey messages resolve.
  // Construct the store directly from the same DB and vault instances;
  // it's a stateless adapter, so a second instance reads/writes the same rows.
  final store = DriftSignalStore(d.db, d.vault);
  for (final entry in d.generated.private.oneTimePrekeysSerialized.entries) {
    await store
        .storePreKey(entry.key, PreKeyRecord.fromBuffer(entry.value));
  }
  await store.storeSignedPreKey(
    d.generated.public.signedPrekeyId,
    SignedPreKeyRecord.fromSerialized(d.generated.private.signedPrekeySerialized),
  );
  return d;
}

void main() {
  test('round-trip: alice encrypts, bob decrypts', () async {
    final registry = <_Device>[];
    final alice = await _makeDevice('alice', 1, registry);
    final bob = await _makeDevice('bob', 1, registry);
    registry.addAll([alice, bob]);

    final copies = await alice.service.encryptFor(
      recipientUserId: 'bob',
      plaintext: Uint8List.fromList(utf8.encode('as-salamu alaykum')),
    );
    expect(copies, hasLength(1));
    expect(copies.single.cipherType, CiphertextMessage.prekeyType,
        reason: 'first message to a device must be a prekey message (3)');

    final plain = await bob.service.decryptFrom(
      senderUserId: 'alice',
      senderDeviceNum: 1,
      ciphertext: copies.single.ciphertext,
      cipherType: copies.single.cipherType,
    );
    expect(utf8.decode(plain), 'as-salamu alaykum');
  });

  test('fan-out: 2 bob devices + alice second device => 3 copies', () async {
    final registry = <_Device>[];
    final alice1 = await _makeDevice('alice', 1, registry);
    final alice2 = await _makeDevice('alice', 2, registry);
    final bob1 = await _makeDevice('bob', 1, registry);
    final bob2 = await _makeDevice('bob', 2, registry);
    registry.addAll([alice1, alice2, bob1, bob2]);

    final copies = await alice1.service.encryptFor(
      recipientUserId: 'bob',
      plaintext: Uint8List.fromList(utf8.encode('hi')),
    );

    expect(copies, hasLength(3));
    expect(
      copies.map((c) => '${c.userId}:${c.deviceNum}').toSet(),
      {'bob:1', 'bob:2', 'alice:2'},
      reason: 'both of bob devices plus alice own other device',
    );
  });

  test('once the prekey is acknowledged, subsequent messages are whisper (2)',
      () async {
    final registry = <_Device>[];
    final alice = await _makeDevice('alice', 1, registry);
    final bob = await _makeDevice('bob', 1, registry);
    registry.addAll([alice, bob]);

    // 1. Alice's first message to Bob establishes the session via X3DH, so
    // it must be a PreKeySignalMessage.
    final first = await alice.service.encryptFor(
        recipientUserId: 'bob', plaintext: Uint8List.fromList([1]));
    expect(first.single.cipherType, CiphertextMessage.prekeyType);

    // 2. Bob decrypts it, establishing his side of the session.
    await bob.service.decryptFrom(
      senderUserId: 'alice',
      senderDeviceNum: 1,
      ciphertext: first.single.ciphertext,
      cipherType: first.single.cipherType,
    );

    // 3. Bob replies. His session came from receiving a prekey message, not
    // from processing a prekey bundle, so he has no "unacknowledged prekey"
    // flag and his message is already a whisper message.
    final reply = await bob.service.encryptFor(
        recipientUserId: 'alice', plaintext: Uint8List.fromList([2]));

    // 4. Alice must DECRYPT Bob's reply to clear her own "unacknowledged
    // prekey" flag. SessionBuilder.processPreKeyBundle sets that flag when
    // Alice establishes the session, and libsignal only clears it when the
    // session's owner decrypts a message from the peer — never when it
    // encrypts. Skipping this step is what made the old version of this test
    // wrong: two consecutive encryptFor calls with no reply in between are
    // BOTH legitimately prekeyType, because until the peer's reply proves
    // they received the session, every message must stay a
    // PreKeySignalMessage so a lost first message can still establish the
    // session.
    await alice.service.decryptFrom(
      senderUserId: 'bob',
      senderDeviceNum: 1,
      ciphertext: reply.single.ciphertext,
      cipherType: reply.single.cipherType,
    );

    // 5. Now that Alice's prekey is acknowledged, her next message to Bob is
    // a plain whisper message.
    final second = await alice.service.encryptFor(
        recipientUserId: 'bob', plaintext: Uint8List.fromList([3]));

    expect(second.single.cipherType, CiphertextMessage.whisperType);
  });
}
