import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart' as sig;

/// Public halves of a device's Signal key bundle. Uploaded to the backend
/// so a spouse's device can perform X3DH later.
class PublicBundle {
  const PublicBundle({
    required this.registrationId,
    required this.deviceId,
    required this.identityPub,
    required this.signedPrekeyId,
    required this.signedPrekeyPub,
    required this.signedPrekeySig,
    required this.oneTimePrekeys,
  });

  final int registrationId;
  final String deviceId;
  final Uint8List identityPub;
  final int signedPrekeyId;
  final Uint8List signedPrekeyPub;
  final Uint8List signedPrekeySig;
  final List<PublicPrekey> oneTimePrekeys;

  Map<String, dynamic> toBundleRow() => {
        'device_id': deviceId,
        'registration_id': registrationId,
        'identity_pub': identityPub,
        'signed_prekey_id': signedPrekeyId,
        'signed_prekey_pub': signedPrekeyPub,
        'signed_prekey_sig': signedPrekeySig,
        'one_time_prekeys':
            oneTimePrekeys.map((p) => p.toJson()).toList(growable: false),
      };
}

class PublicPrekey {
  const PublicPrekey({required this.id, required this.pub});
  final int id;
  final Uint8List pub;

  Map<String, dynamic> toJson() => {
        'id': id,
        'pub': base64Encode(pub),
      };
}

/// The privates that must never leave the device. Written to secure storage.
class PrivateBundle {
  const PrivateBundle({
    required this.identitySerialized,
    required this.signedPrekeySerialized,
    required this.oneTimePrekeysSerialized,
    required this.registrationId,
  });

  /// [sig.IdentityKeyPair.serialize] output — identity keypair.
  final Uint8List identitySerialized;

  /// [sig.SignedPreKeyRecord.serialize] output.
  final Uint8List signedPrekeySerialized;

  /// Map of prekey id → [sig.PreKeyRecord.serialize] output.
  final Map<int, Uint8List> oneTimePrekeysSerialized;

  /// Registration ID from libsignal, persisted for IdentityKeyStore.getLocalRegistrationId().
  final int registrationId;
}

class GeneratedKeyBundle {
  const GeneratedKeyBundle({required this.public, required this.private});
  final PublicBundle public;
  final PrivateBundle private;
}

/// Generate a fresh Signal identity + prekeys for a new device.
///
/// [deviceId] uniquely identifies this device for the user (e.g. install UUID).
/// [oneTimePrekeyCount] is how many one-time prekeys to generate up front.
GeneratedKeyBundle generateBundle({
  required String deviceId,
  int oneTimePrekeyCount = 20,
}) {
  final identity = sig.generateIdentityKeyPair();
  final registrationId = sig.generateRegistrationId(false);
  const signedPrekeyId = 1;
  final signedPrekey = sig.generateSignedPreKey(identity, signedPrekeyId);
  final oneTimePrekeys = sig.generatePreKeys(1, oneTimePrekeyCount);

  final publicOtps = oneTimePrekeys
      .map((p) => PublicPrekey(
            id: p.id,
            pub: p.getKeyPair().publicKey.serialize(),
          ))
      .toList(growable: false);

  final privateOtps = <int, Uint8List>{
    for (final p in oneTimePrekeys) p.id: p.serialize(),
  };

  return GeneratedKeyBundle(
    public: PublicBundle(
      registrationId: registrationId,
      deviceId: deviceId,
      identityPub: identity.getPublicKey().serialize(),
      signedPrekeyId: signedPrekey.id,
      signedPrekeyPub: signedPrekey.getKeyPair().publicKey.serialize(),
      signedPrekeySig: signedPrekey.signature,
      oneTimePrekeys: publicOtps,
    ),
    private: PrivateBundle(
      identitySerialized: identity.serialize(),
      signedPrekeySerialized: signedPrekey.serialize(),
      oneTimePrekeysSerialized: privateOtps,
      registrationId: registrationId,
    ),
  );
}
