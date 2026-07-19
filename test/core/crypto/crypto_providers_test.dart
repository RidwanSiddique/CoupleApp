// test/core/crypto/crypto_providers_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/crypto/crypto_providers.dart';
import 'package:sakinah/core/crypto/prekey_bundle_source.dart';
import 'package:sakinah/core/crypto/signal_session_service.dart';
import 'package:sakinah/core/storage/signal_db.dart';

/// No-op stand-in for the real Supabase-backed bundle source. Real
/// [SupabasePreKeyBundleSource] needs a live [SupabaseClient], which
/// `supabaseClientProvider` only supplies once overridden at the app's
/// [ProviderScope] root (see shared/providers/supabase_provider.dart) — not
/// available in a bare unit test, so the "does the provider graph assemble"
/// test below overrides [preKeyBundleSourceProvider] and [selfUserIdProvider]
/// directly instead of standing up a real Supabase client.
class _NoopBundleSource implements PreKeyBundleSource {
  @override
  Future<List<int>> deviceNumsFor(String userId) async => const [];

  @override
  Future<DeviceBundle?> bundleFor(String userId, int deviceNum) async => null;
}

void main() {
  test('signalDbProvider is a singleton within a container', () {
    // Overridden with an in-memory SignalDb, not the bare (default)
    // ProviderContainer the brief sketched: the real signalDbProvider opens
    // an on-disk driftDatabase() that calls path_provider over a platform
    // channel, which needs Flutter binding initialization this plain
    // `flutter_test` run doesn't have (no precedent for mocking that channel
    // anywhere in this suite — every other test uses SignalDb.memory()).
    // The identity check below still exercises the exact same provider
    // machinery; only the underlying db implementation changes.
    final c = ProviderContainer(overrides: [
      signalDbProvider.overrideWith((ref) {
        final db = SignalDb.memory();
        ref.onDispose(db.close);
        return db;
      }),
    ]);
    addTearDown(c.dispose);
    final a = c.read(signalDbProvider);
    final b = c.read(signalDbProvider);
    expect(identical(a, b), isTrue);
  });

  test('signalSessionServiceProvider builds', () {
    final c = ProviderContainer(overrides: [
      signalDbProvider.overrideWith((ref) {
        final db = SignalDb.memory();
        ref.onDispose(db.close);
        return db;
      }),
      preKeyBundleSourceProvider.overrideWith((ref) => _NoopBundleSource()),
      selfUserIdProvider.overrideWith((ref) => 'test-user'),
    ]);
    addTearDown(c.dispose);
    expect(c.read(signalSessionServiceProvider), isA<SignalSessionService>());
  });
}
