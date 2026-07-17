// test/core/crypto/prekey_bundle_source_test.dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:sakinah/core/crypto/prekey_bundle_source.dart';

void main() {
  test('DeviceBundle converts to a libsignal PreKeyBundle', () {
    final identity = generateIdentityKeyPair();
    final signed = generateSignedPreKey(identity, 7);
    final otp = generatePreKeys(1, 1).first;

    final b = DeviceBundle(
      deviceNum: 2,
      registrationId: 1234,
      identityPub: identity.getPublicKey().serialize(),
      signedPrekeyId: 7,
      signedPrekeyPub: signed.getKeyPair().publicKey.serialize(),
      signedPrekeySig: signed.signature,
      oneTimePrekeyId: otp.id,
      oneTimePrekeyPub: otp.getKeyPair().publicKey.serialize(),
    );

    final bundle = b.toPreKeyBundle();
    expect(bundle.getDeviceId(), 2);
    expect(bundle.getSignedPreKeyId(), 7);
    expect(bundle.getPreKeyId(), otp.id);
  });

  test('DeviceBundle without a one-time prekey still converts (exhausted)', () {
    final identity = generateIdentityKeyPair();
    final signed = generateSignedPreKey(identity, 1);

    final b = DeviceBundle(
      deviceNum: 1,
      registrationId: 9,
      identityPub: identity.getPublicKey().serialize(),
      signedPrekeyId: 1,
      signedPrekeyPub: signed.getKeyPair().publicKey.serialize(),
      signedPrekeySig: signed.signature,
      oneTimePrekeyId: null,
      oneTimePrekeyPub: null,
    );

    final bundle = b.toPreKeyBundle();
    expect(bundle.getPreKeyId(), isNull);
    expect(bundle.getPreKey(), isNull);
  });
}
