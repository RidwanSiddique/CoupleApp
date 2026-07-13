import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/couple.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../auth/domain/auth_controller.dart';
import '../data/pairing_repository.dart';

final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  return PairingRepository(ref.read(supabaseClientProvider));
});

/// The current user's couple (null when unpaired). Live via realtime.
///
/// Emits null immediately when there is no session, so downstream consumers
/// (router redirect, home screen) see a resolved value rather than staying
/// in a permanent loading state after sign-out.
final currentCoupleProvider = StreamProvider<Couple?>((ref) {
  final session = ref.watch(authSessionProvider).asData?.value;
  if (session == null) return Stream.value(null);
  return ref
      .read(pairingRepositoryProvider)
      .watchCurrentCouple(session.user.id);
});
