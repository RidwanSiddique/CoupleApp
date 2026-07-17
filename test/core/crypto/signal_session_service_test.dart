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

  test('RESTART SURVIVAL: a session rebuilt from the DB still decrypts',
      () async {
    final registry = <_Device>[];
    final alice = await _makeDevice('alice', 1, registry);
    final bob = await _makeDevice('bob', 1, registry);
    registry.addAll([alice, bob]);

    final first = await alice.service.encryptFor(
        recipientUserId: 'bob',
        plaintext: Uint8List.fromList(utf8.encode('before restart')));

    await bob.service.decryptFrom(
      senderUserId: 'alice',
      senderDeviceNum: 1,
      ciphertext: first.single.ciphertext,
      cipherType: first.single.cipherType,
    );

    // Bob replies and alice decrypts it. This acknowledges alice's pending
    // prekey (see the "once acknowledged" test above for why that flag
    // exists), which is essential to this test's integrity: without it,
    // alice's post-restart message below would still legitimately be a
    // PreKeySignalMessage, and a PreKeySignalMessage can establish a BRAND
    // NEW session via processPreKeyBundle-style logic if bob's ratchet state
    // failed to persist — so the test would still pass even with broken
    // persistence, proving nothing. Forcing the exchange onto the whisper
    // path below is what makes the assertion below undeniable: a whisper
    // message has no session-establishment fallback. bob's decryptFrom must
    // find a REAL, PERSISTED session or it throws NoSessionException.
    final bobReply = await bob.service.encryptFor(
        recipientUserId: 'alice',
        plaintext: Uint8List.fromList(utf8.encode('got it')));
    await alice.service.decryptFrom(
      senderUserId: 'bob',
      senderDeviceNum: 1,
      ciphertext: bobReply.single.ciphertext,
      cipherType: bobReply.single.cipherType,
    );

    // Simulate an app restart: brand new service over the SAME db + vault.
    // Reusing bob.db and bob.vault (not fresh instances) is the crux of this
    // test: it proves the ratchet state was actually written to and read
    // back from durable storage, not merely held in the old service's
    // in-memory session cache.
    final revived = SignalSessionService(
      db: bob.db,
      vault: bob.vault,
      bundles: _FakeBundles(registry),
      selfUserId: 'bob',
      selfDeviceNum: 1,
    );

    final second = await alice.service.encryptFor(
        recipientUserId: 'bob',
        plaintext: Uint8List.fromList(utf8.encode('after restart')));

    // The key assertion: because bob's reply was decrypted above, alice's
    // prekey is acknowledged and this message MUST be a whisper message, not
    // a prekey message. A whisper message cannot silently fall back to
    // establishing a fresh X3DH session, so the decrypt below can only
    // succeed if bob's session state genuinely survived the restart.
    expect(second.single.cipherType, CiphertextMessage.whisperType,
        reason: 'prekey must already be acknowledged, forcing the '
            'post-restart message onto the whisper (no-fallback) path');

    final plain = await revived.decryptFrom(
      senderUserId: 'alice',
      senderDeviceNum: 1,
      ciphertext: second.single.ciphertext,
      cipherType: second.single.cipherType,
    );
    expect(utf8.decode(plain), 'after restart',
        reason: 'ratchet state must persist across a restart');
  });

  test('OUT-OF-ORDER: messages delivered 3,1,2 all decrypt', () async {
    final registry = <_Device>[];
    final alice = await _makeDevice('alice', 1, registry);
    final bob = await _makeDevice('bob', 1, registry);
    registry.addAll([alice, bob]);

    final msgs = <EncryptedCopy>[];
    for (final t in ['one', 'two', 'three']) {
      final c = await alice.service.encryptFor(
          recipientUserId: 'bob',
          plaintext: Uint8List.fromList(utf8.encode(t)));
      msgs.add(c.single);
    }

    final got = <String>[];
    for (final i in [2, 0, 1]) {
      final plain = await bob.service.decryptFrom(
        senderUserId: 'alice',
        senderDeviceNum: 1,
        ciphertext: msgs[i].ciphertext,
        cipherType: msgs[i].cipherType,
      );
      got.add(utf8.decode(plain));
    }
    expect(got, ['three', 'one', 'two']);
  });

  test('PREKEY EXHAUSTION: session still establishes from the signed prekey',
      () async {
    final registry = <_Device>[];
    final alice = await _makeDevice('alice', 1, registry);
    final bob = await _makeDevice('bob', 1, registry);
    registry.addAll([alice, bob]);

    // Bundle source that has run out of one-time prekeys.
    final exhausted = _ExhaustedBundles([bob]);
    final svc = SignalSessionService(
      db: alice.db,
      vault: alice.vault,
      bundles: exhausted,
      selfUserId: 'alice',
      selfDeviceNum: 1,
    );

    final copies = await svc.encryptFor(
        recipientUserId: 'bob', plaintext: Uint8List.fromList(utf8.encode('hi')));

    expect(copies, hasLength(1));
    expect(copies.single.cipherType, CiphertextMessage.prekeyType);
  });
}

/// Bundle source whose devices have no one-time prekeys left.
class _ExhaustedBundles implements PreKeyBundleSource {
  _ExhaustedBundles(this.devices);
  final List<_Device> devices;

  @override
  Future<List<DeviceBundle>> bundlesFor(String userId) async {
    return devices.where((d) => d.userId == userId).map((d) {
      final p = d.generated.public;
      return DeviceBundle(
        deviceNum: d.deviceNum,
        registrationId: p.registrationId,
        identityPub: p.identityPub,
        signedPrekeyId: p.signedPrekeyId,
        signedPrekeyPub: p.signedPrekeyPub,
        signedPrekeySig: p.signedPrekeySig,
        oneTimePrekeyId: null,
        oneTimePrekeyPub: null,
      );
    }).toList();
  }
}
