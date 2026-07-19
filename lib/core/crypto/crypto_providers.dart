// lib/core/crypto/crypto_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../features/auth/domain/auth_controller.dart' show keyVaultProvider;
import '../../shared/providers/supabase_provider.dart';
import '../storage/signal_db.dart';
import 'prekey_bundle_source.dart';
import 'signal_registration.dart';
import 'signal_session_service.dart';

/// One SignalDb for the app's lifetime (opens the on-disk `sakinah_signal` db).
final signalDbProvider = Provider<SignalDb>((ref) {
  final db = SignalDb();
  ref.onDispose(db.close);
  return db;
});

final deviceRegistrarProvider = Provider<DeviceRegistrar>((ref) {
  return SupabaseDeviceRegistrar(ref.read(supabaseClientProvider));
});

final preKeyBundleSourceProvider = Provider<PreKeyBundleSource>((ref) {
  return SupabasePreKeyBundleSource(ref.read(supabaseClientProvider));
});

/// This device's own user id, read from the live Supabase session. A separate
/// provider (rather than reading `supabaseClientProvider` inline wherever a
/// user id is needed) so it can be overridden in tests without standing up a
/// real `SupabaseClient`.
final selfUserIdProvider = Provider<String>((ref) {
  return ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';
});

/// This device's assigned device_num. Zero until [ensureRegisteredProvider]
/// has run at least once in this process; every real call site awaits that
/// before touching [signalSessionServiceProvider], so the zero default is
/// never observed in practice.
final selfDeviceNumProvider = StateProvider<int>((ref) => 0);

final signalSessionServiceProvider = Provider<SignalSessionService>((ref) {
  return SignalSessionService(
    db: ref.watch(signalDbProvider),
    vault: ref.read(keyVaultProvider),
    bundles: ref.read(preKeyBundleSourceProvider),
    selfUserId: ref.watch(selfUserIdProvider),
    selfDeviceNum: ref.watch(selfDeviceNumProvider),
  );
});

/// Registers this device (idempotent) + tops up prekeys, and records the
/// resulting device_num so [signalSessionServiceProvider] picks it up on the
/// next rebuild. Call after auth.
final ensureRegisteredProvider = Provider<Future<int> Function()>((ref) {
  return () async {
    final deviceNum = await ensureRegistered(
      db: ref.read(signalDbProvider),
      vault: ref.read(keyVaultProvider),
      registrar: ref.read(deviceRegistrarProvider),
    );
    ref.read(selfDeviceNumProvider.notifier).state = deviceNum;
    return deviceNum;
  };
});
