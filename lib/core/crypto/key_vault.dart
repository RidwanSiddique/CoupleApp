import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'signal_keys.dart';

/// Persists Signal private material in platform secure storage (Keychain / Keystore).
class KeyVault {
  KeyVault(this._storage);

  final FlutterSecureStorage _storage;

  static const _identityKey = 'signal.identity.priv';
  static const _spkKey = 'signal.spk.priv';
  static const _otpkPrefix = 'signal.otpk.';
  static const _deviceIdKey = 'signal.device_id';

  Future<bool> hasIdentity() async {
    final v = await _storage.read(key: _identityKey);
    return v != null && v.isNotEmpty;
  }

  Future<String?> deviceId() => _storage.read(key: _deviceIdKey);

  Future<void> saveDeviceId(String id) =>
      _storage.write(key: _deviceIdKey, value: id);

  Future<void> savePrivate(PrivateBundle bundle) async {
    await _storage.write(
      key: _identityKey,
      value: base64Encode(bundle.identitySerialized),
    );
    await _storage.write(
      key: _spkKey,
      value: base64Encode(bundle.signedPrekeySerialized),
    );
    for (final entry in bundle.oneTimePrekeysSerialized.entries) {
      await _storage.write(
        key: '$_otpkPrefix${entry.key}',
        value: base64Encode(entry.value),
      );
    }
  }

  Future<Uint8List?> readIdentity() async {
    final v = await _storage.read(key: _identityKey);
    if (v == null) return null;
    return Uint8List.fromList(base64Decode(v));
  }

  Future<void> wipe() async {
    await _storage.deleteAll();
  }
}
