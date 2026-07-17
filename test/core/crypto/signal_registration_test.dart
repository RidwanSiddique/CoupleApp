import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/crypto/key_vault.dart';
import 'package:sakinah/core/crypto/secure_store.dart';
import 'package:sakinah/core/crypto/signal_keys.dart';
import 'package:sakinah/core/crypto/signal_registration.dart';

class _FakeRegistrar implements DeviceRegistrar {
  int? registeredDeviceNum;
  Map<int, Uint8List> uploaded = {};
  int remaining = 0;

  @override
  Future<int> register({
    required String deviceId,
    required int registrationId,
    required Uint8List identityPub,
    required int signedPrekeyId,
    required Uint8List signedPrekeyPub,
    required Uint8List signedPrekeySig,
  }) async {
    registeredDeviceNum = 1;
    return 1;
  }

  @override
  Future<void> uploadOneTimePrekeys({
    required int deviceNum,
    required Map<int, Uint8List> prekeys,
  }) async =>
      uploaded.addAll(prekeys);

  @override
  Future<int> unconsumedPrekeyCount(int deviceNum) async => remaining;
}

void main() {
  test('ensureRegistered generates, registers and persists the device number',
      () async {
    final vault = KeyVault(InMemorySecureStore());
    final registrar = _FakeRegistrar();

    final deviceNum = await ensureRegistered(vault: vault, registrar: registrar);

    expect(deviceNum, 1);
    expect(await vault.readDeviceNum(), 1);
    expect(await vault.hasIdentity(), isTrue);
    expect(await vault.readRegistrationId(), isNotNull);
    expect(registrar.uploaded, isNotEmpty);
  });

  test('ensureRegistered is idempotent — a second call keeps the identity',
      () async {
    final vault = KeyVault(InMemorySecureStore());
    final registrar = _FakeRegistrar();

    await ensureRegistered(vault: vault, registrar: registrar);
    final firstIdentity = await vault.readIdentity();

    await ensureRegistered(vault: vault, registrar: registrar);

    expect(await vault.readIdentity(), firstIdentity,
        reason: 'regenerating the identity would break every session');
  });

  test(
      'resumes without regenerating the identity when device_num was never persisted',
      () async {
    final vault = KeyVault(InMemorySecureStore());

    // Seed the exact partial state: savePrivate + saveDeviceId succeeded
    // (as ensureRegistered does before the network round-trip), but
    // saveDeviceNum never ran — simulating the app dying or the network
    // dropping between the two.
    final seed = generateBundle(deviceId: 'd');
    await vault.savePrivate(seed.private);
    await vault.saveDeviceId('d');

    final before = await vault.readIdentity();
    final registrationIdBefore = await vault.readRegistrationId();
    expect(await vault.readDeviceNum(), isNull);

    final deviceNum =
        await ensureRegistered(vault: vault, registrar: _FakeRegistrar());

    expect(await vault.readIdentity(), before,
        reason:
            'resuming a partial registration must preserve the existing identity');
    expect(await vault.readRegistrationId(), registrationIdBefore);
    expect(await vault.readDeviceNum(), deviceNum);
    expect(await vault.readDeviceNum(), isNotNull);
  });
}
