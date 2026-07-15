import '../../../core/time/prayer_engine.dart';
import '../../../shared/models/cycle_record.dart';

const int prayersPerDay = 5;

class DayLog {
  const DayLog({required this.date, required this.prayed});
  final DateTime date;
  final Set<Prayer> prayed;
}

class ScoreResult {
  const ScoreResult({
    required this.prayed,
    required this.due,
    required this.currentStreak,
    required this.longestStreak,
  });
  final int prayed;
  final int due;
  final int currentStreak;
  final int longestStreak;
  double get pct => due == 0 ? 1.0 : prayed / due;
}

DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

bool isExempt(List<CycleRecord> cycles, DateTime day) {
  for (final c in cycles) {
    if (c.isActiveOn(day)) return true;
  }
  return false;
}

ScoreResult computeScore({
  required List<DayLog> logs,
  required List<CycleRecord> cycles,
  required DateTime from,
  required DateTime toInclusive,
}) {
  final byDate = <DateTime, Set<Prayer>>{
    for (final l in logs) _d(l.date): l.prayed,
  };

  var due = 0;
  var prayed = 0;
  var current = 0;
  var longest = 0;
  var streakBroken = false; // once we hit a missed (non-exempt) day, current stops growing

  // Walk newest -> oldest for current-streak semantics.
  final days = <DateTime>[];
  for (var d = _d(toInclusive);
      !d.isBefore(_d(from));
      d = d.subtract(const Duration(days: 1))) {
    days.add(d);
  }

  var run = 0;
  for (final day in days) {
    if (isExempt(cycles, day)) {
      // Frozen: neither counts toward due/prayed nor breaks a streak.
      continue;
    }
    due += prayersPerDay;
    final p = byDate[day]?.length ?? 0;
    prayed += p;
    final complete = p >= prayersPerDay;
    if (complete) {
      run += 1;
      if (run > longest) longest = run;
      if (!streakBroken) current = run;
    } else {
      run = 0;
      streakBroken = true;
    }
  }

  return ScoreResult(
    prayed: prayed, due: due,
    currentStreak: current, longestStreak: longest);
}
