import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'key_vault.dart';
import 'signal_keys.dart';

abstract class DeviceRegistrar {
  Future<int> register({
    required String deviceId,
    required int registrationId,
    required Uint8List identityPub,
    required int signedPrekeyId,
    required Uint8List signedPrekeyPub,
    required Uint8List signedPrekeySig,
  });

  Future<void> uploadOneTimePrekeys({
    required int deviceNum,
    required Map<int, Uint8List> prekeys,
  });

  Future<int> unconsumedPrekeyCount(int deviceNum);
}

class SupabaseDeviceRegistrar implements DeviceRegistrar {
  SupabaseDeviceRegistrar(this._client);

  final SupabaseClient _client;

  @override
  Future<int> register({
    required String deviceId,
    required int registrationId,
    required Uint8List identityPub,
    required int signedPrekeyId,
    required Uint8List signedPrekeyPub,
    required Uint8List signedPrekeySig,
  }) async {
    final res = await _client.rpc('register_device_bundle', params: {
      'p_device_id': deviceId,
      'p_registration_id': registrationId,
      'p_identity_pub': identityPub,
      'p_signed_prekey_id': signedPrekeyId,
      'p_signed_prekey_pub': signedPrekeyPub,
      'p_signed_prekey_sig': signedPrekeySig,
    });
    return res as int;
  }

  @override
  Future<void> uploadOneTimePrekeys({
    required int deviceNum,
    required Map<int, Uint8List> prekeys,
  }) async {
    final uid = _client.auth.currentUser!.id;
    await _client.from('signal_one_time_prekeys').upsert([
      for (final e in prekeys.entries)
        {
          'user_id': uid,
          'device_num': deviceNum,
          'prekey_id': e.key,
          'pub': e.value,
        }
    ]);
  }

  @override
  Future<int> unconsumedPrekeyCount(int deviceNum) async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('signal_one_time_prekeys')
        .select('prekey_id')
        .eq('user_id', uid)
        .eq('device_num', deviceNum)
        .isFilter('consumed_at', null);
    return (rows as List).length;
  }
}

/// Generate + publish this device's identity once. Idempotent: an existing
/// identity is never regenerated, because that would break every session.
Future<int> ensureRegistered({
  required KeyVault vault,
  required DeviceRegistrar registrar,
  int oneTimePrekeyCount = 20,
}) async {
  final existingNum = await vault.readDeviceNum();
  if (await vault.hasIdentity() && existingNum != null) return existingNum;

  var deviceId = await vault.deviceId();
  deviceId ??= const Uuid().v4();
  await vault.saveDeviceId(deviceId);

  final generated =
      generateBundle(deviceId: deviceId, oneTimePrekeyCount: oneTimePrekeyCount);
  await vault.savePrivate(generated.private);

  final pub = generated.public;
  final deviceNum = await registrar.register(
    deviceId: deviceId,
    registrationId: pub.registrationId,
    identityPub: pub.identityPub,
    signedPrekeyId: pub.signedPrekeyId,
    signedPrekeyPub: pub.signedPrekeyPub,
    signedPrekeySig: pub.signedPrekeySig,
  );
  await vault.saveDeviceNum(deviceNum);

  await registrar.uploadOneTimePrekeys(
    deviceNum: deviceNum,
    prekeys: {for (final p in pub.oneTimePrekeys) p.id: p.pub},
  );
  return deviceNum;
}
