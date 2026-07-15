import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../auth/domain/auth_controller.dart';
import '../../pairing/domain/pairing_providers.dart';
import '../../home/domain/home_providers.dart';
import '../../cycle/domain/cycle_providers.dart';
import '../data/scoreboard_repository.dart';
import 'score_engine.dart';

final scoreboardRepositoryProvider = Provider<ScoreboardRepository>((ref) {
  return ScoreboardRepository(ref.read(supabaseClientProvider));
});

class CoupleScoreboard {
  const CoupleScoreboard({
    required this.own,
    required this.spouse,
    required this.spouseCycleShared,
  });
  final ScoreResult own;
  final ScoreResult spouse;
  // Vestigial now that scores are computed server-side (RPC never exposes
  // the spouse's private cycle rows regardless of sharing), kept only for
  // source compatibility with call sites that still reference it.
  final bool spouseCycleShared;
}

/// Window length in days for the headline comparison.
const int scoreWindowDays = 30;

/// Computes both members' scores via the `get_couple_scoreboard` SECURITY
/// DEFINER RPC (see `supabase/migrations/20260715000005_scoreboard_rpc.sql`).
/// The RPC reads each member's own cycle_records server-side (bypassing RLS)
/// so a wife's private cycle exemptions apply correctly to her score without
/// ever exposing her cycle rows to her husband's device.
final scoreboardProvider = FutureProvider<CoupleScoreboard?>((ref) async {
  final session = ref.watch(authSessionProvider).asData?.value;
  final couple = ref.watch(currentCoupleProvider).asData?.value;
  if (session == null || couple == null) return null;

  // Recompute when today's logs change, or when own cycle history changes
  // (starting/ending a cycle should immediately re-run the scoreboard).
  ref.watch(prayerLogRefreshTickProvider);
  ref.watch(ownCycleHistoryProvider);

  final client = ref.read(supabaseClientProvider);
  final myId = session.user.id;
  final spouseId = couple.spouseOf(myId);

  final rows = await client
      .rpc('get_couple_scoreboard', params: {'p_window_days': scoreWindowDays});

  ScoreResult? own;
  ScoreResult? spouse;
  for (final r in (rows as List)) {
    final m = Map<String, dynamic>.from(r as Map);
    final result = ScoreResult(
      prayed: m['prayed'] as int,
      due: m['due'] as int,
      currentStreak: m['current_streak'] as int,
      longestStreak: m['longest_streak'] as int,
    );
    if (m['member_id'] == myId) {
      own = result;
    } else if (m['member_id'] == spouseId) {
      spouse = result;
    }
  }
  if (own == null || spouse == null) return null;

  return CoupleScoreboard(own: own, spouse: spouse, spouseCycleShared: false);
});
