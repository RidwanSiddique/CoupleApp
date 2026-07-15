import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/supabase_provider.dart';
import '../../auth/domain/auth_controller.dart';
import '../../pairing/domain/pairing_providers.dart';
import '../../home/domain/home_providers.dart';
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
  final bool spouseCycleShared;
}

/// Window length in days for the headline comparison.
const int scoreWindowDays = 30;

final scoreboardProvider = FutureProvider<CoupleScoreboard?>((ref) async {
  final session = ref.watch(authSessionProvider).asData?.value;
  final couple = ref.watch(currentCoupleProvider).asData?.value;
  if (session == null || couple == null) return null;

  // Recompute when today's logs change.
  ref.watch(prayerLogRefreshTickProvider);

  final repo = ref.read(scoreboardRepositoryProvider);
  final today = DateTime.now();
  final toInclusive = today.subtract(const Duration(days: 1)); // completed days only
  final from = toInclusive.subtract(const Duration(days: scoreWindowDays - 1));

  final myId = session.user.id;
  final spouseId = couple.spouseOf(myId);

  final ownLogs = await repo.fetchDayLogs(
      coupleId: couple.id, userId: myId, from: from, toInclusive: toInclusive);
  final ownCycles = await repo.fetchCycles(userId: myId, from: from, toInclusive: toInclusive);
  final spouseLogs = await repo.fetchDayLogs(
      coupleId: couple.id, userId: spouseId, from: from, toInclusive: toInclusive);
  // Spouse cycles are only readable when shared (RLS). Empty => not shared / none.
  final spouseCycles = await repo.fetchCycles(
      userId: spouseId, from: from, toInclusive: toInclusive);

  final own = computeScore(logs: ownLogs, cycles: ownCycles, from: from, toInclusive: toInclusive);
  final spouse = computeScore(
      logs: spouseLogs, cycles: spouseCycles, from: from, toInclusive: toInclusive);

  return CoupleScoreboard(
    own: own, spouse: spouse, spouseCycleShared: spouseCycles.isNotEmpty);
});
