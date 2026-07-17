import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/crypto/key_vault.dart';
import 'package:sakinah/core/crypto/secure_store.dart';
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
}
