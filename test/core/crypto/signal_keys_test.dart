import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as sig;
import 'package:sakinah/core/crypto/signal_keys.dart';

void main() {
  test('generateBundle produces a signed prekey verifiable against identity',
      () {
    final bundle = generateBundle(deviceId: 'test-device', oneTimePrekeyCount: 3);

    // Identity public key should verify the SPK signature.
    final identityPub = sig.Curve.decodePoint(bundle.public.identityPub, 0);
    final verified = sig.Curve.verifySignature(
      identityPub,
      bundle.public.signedPrekeyPub,
      bundle.public.signedPrekeySig,
    );

    expect(verified, isTrue);
  });

  test('generateBundle yields the requested number of one-time prekeys', () {
    final bundle = generateBundle(deviceId: 'd', oneTimePrekeyCount: 7);
    expect(bundle.public.oneTimePrekeys, hasLength(7));
    expect(bundle.private.oneTimePrekeysSerialized, hasLength(7));
  });

  test('two invocations produce distinct identity keys', () {
    final a = generateBundle(deviceId: 'a', oneTimePrekeyCount: 1);
    final b = generateBundle(deviceId: 'b', oneTimePrekeyCount: 1);
    expect(a.public.identityPub, isNot(equals(b.public.identityPub)));
  });
}
