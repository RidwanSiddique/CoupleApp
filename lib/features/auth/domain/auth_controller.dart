import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/key_vault.dart';
import '../../../core/crypto/signal_keys.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../data/auth_repository.dart';

final keyVaultProvider = Provider<KeyVault>((ref) {
  return KeyVault(ref.read(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(supabaseClientProvider),
    ref.read(keyVaultProvider),
  );
});

/// Broadcasts the current [Session] (null when signed out).
final authSessionProvider = StreamProvider<Session?>((ref) {
  final repo = ref.read(authRepositoryProvider);
  final controller = StreamController<Session?>();
  controller.add(repo.currentSession);
  final sub = repo.authStateChanges().listen((state) {
    controller.add(state.session);
  });
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Runs after signup to ensure the user has a Signal identity + uploaded bundle.
class SignalIdentityBootstrap {
  SignalIdentityBootstrap(this._client, this._vault);

  final SupabaseClient _client;
  final KeyVault _vault;

  /// Idempotent: if the vault already has an identity, no-op.
  Future<void> ensureBundle() async {
    if (await _vault.hasIdentity()) return;

    var deviceId = await _vault.deviceId();
    deviceId ??= const Uuid().v4();
    await _vault.saveDeviceId(deviceId);

    final generated = generateBundle(deviceId: deviceId);
    await _vault.savePrivate(generated.private);

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return; // shouldn't happen post-verify
    final row = {
      'user_id': userId,
      ...generated.public.toBundleRow(),
    };
    await _client.from('signal_key_bundles').upsert(row);
  }
}

final signalBootstrapProvider = Provider<SignalIdentityBootstrap>((ref) {
  return SignalIdentityBootstrap(
    ref.read(supabaseClientProvider),
    ref.read(keyVaultProvider),
  );
});
