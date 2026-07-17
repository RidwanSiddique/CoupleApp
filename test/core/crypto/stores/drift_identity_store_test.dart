import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:sakinah/core/crypto/key_vault.dart';
import 'package:sakinah/core/crypto/secure_store.dart';
import 'package:sakinah/core/crypto/signal_keys.dart';
import 'package:sakinah/core/crypto/stores/drift_identity_store.dart';
import 'package:sakinah/core/storage/signal_db.dart';

void main() {
  late SignalDb db;
  late KeyVault vault;
  late DriftIdentityStore store;

  setUp(() async {
    db = SignalDb.memory();
    vault = KeyVault(InMemorySecureStore());
    await vault.savePrivate(
        generateBundle(deviceId: 'd', oneTimePrekeyCount: 1).private);
    store = DriftIdentityStore(db, vault);
  });
  tearDown(() => db.close());

  test('exposes the local identity pair and registration id', () async {
    expect(await store.getIdentityKeyPair(), isA<IdentityKeyPair>());
    expect(await store.getLocalRegistrationId(), isA<int>());
  });

  test('first save is trust-on-first-use: no change event', () async {
    final addr = SignalProtocolAddress('bob', 1);
    final bob = generateIdentityKeyPair().getPublicKey();

    final replaced = await store.saveIdentity(addr, bob);

    expect(replaced, isFalse, reason: 'nothing was replaced on first use');
    expect((await store.getIdentity(addr))!.serialize(), bob.serialize());
    expect(await db.select(db.signalIdentityChanges).get(), isEmpty);
  });

  test('changed identity is accepted AND recorded', () async {
    final addr = SignalProtocolAddress('bob', 1);
    await store.saveIdentity(addr, generateIdentityKeyPair().getPublicKey());

    final newKey = generateIdentityKeyPair().getPublicKey();
    final replaced = await store.saveIdentity(addr, newKey);

    expect(replaced, isTrue);
    expect((await store.getIdentity(addr))!.serialize(), newKey.serialize());
    final changes = await db.select(db.signalIdentityChanges).get();
    expect(changes, hasLength(1));
    expect(changes.single.name, 'bob');
  });

  test('isTrustedIdentity accepts a changed key (accept-but-warn policy)',
      () async {
    final addr = SignalProtocolAddress('bob', 1);
    await store.saveIdentity(addr, generateIdentityKeyPair().getPublicKey());

    final trusted = await store.isTrustedIdentity(
        addr, generateIdentityKeyPair().getPublicKey(), Direction.sending);

    expect(trusted, isTrue);
  });
}
