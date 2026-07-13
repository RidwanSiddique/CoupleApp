import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/time/prayer_engine.dart';
import 'package:sakinah/core/time/timezone_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initTimezones();
  });

  const london = PrayerLocation(
    latitude: 51.5074,
    longitude: -0.1278,
    timezone: 'Europe/London',
  );

  const mecca = PrayerLocation(
    latitude: 21.4225,
    longitude: 39.8262,
    timezone: 'Asia/Riyadh',
  );

  const nyc = PrayerLocation(
    latitude: 40.7128,
    longitude: -74.0060,
    timezone: 'America/New_York',
  );

  test('returns five prayers ordered by time', () {
    final times = prayerTimesForDay(
      date: DateTime(2026, 3, 20),
      loc: london,
    );

    expect(times.map((p) => p.prayer), [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ]);

    for (var i = 1; i < times.length; i++) {
      expect(
        times[i].at.isAfter(times[i - 1].at),
        isTrue,
        reason: '${times[i].prayer} must be after ${times[i - 1].prayer}',
      );
    }
  });

  test('Hanafi Asr is later than Shafi Asr', () {
    final shafi = prayerTimesForDay(
      date: DateTime(2026, 6, 15),
      loc: mecca,
      config: const PrayerConfig(madhab: Madhab.shafi),
    ).firstWhere((p) => p.prayer == Prayer.asr);

    final hanafi = prayerTimesForDay(
      date: DateTime(2026, 6, 15),
      loc: mecca,
      config: const PrayerConfig(madhab: Madhab.hanafi),
    ).firstWhere((p) => p.prayer == Prayer.asr);

    expect(hanafi.at.isAfter(shafi.at), isTrue);
  });

  test('DST spring-forward: 2026-03-08 New York Fajr is in EDT', () {
    // After DST switches on 2026-03-08, offset is UTC-4.
    final afterDst = prayerTimesForDay(
      date: DateTime(2026, 3, 10),
      loc: nyc,
    ).first;

    expect(afterDst.at.timeZoneOffset, const Duration(hours: -4));
  });

  test('DST fall-back: 2026-11-05 New York Fajr is in EST', () {
    final afterFallBack = prayerTimesForDay(
      date: DateTime(2026, 11, 5),
      loc: nyc,
    ).first;

    expect(afterFallBack.at.timeZoneOffset, const Duration(hours: -5));
  });

  test('nextPrayer picks tomorrow Fajr when today has passed', () {
    final lateNight = DateTime.utc(2026, 3, 20, 23, 59);
    final next = nextPrayer(now: lateNight, loc: london);
    expect(next.prayer, Prayer.fajr);
    expect(next.at.day, 21);
  });

  test('syncGap is commutative and always non-negative', () {
    final a = DateTime.utc(2026, 6, 1, 5, 15);
    final b = DateTime.utc(2026, 6, 1, 5, 30);
    expect(syncGap(a: a, b: b), const Duration(minutes: 15));
    expect(syncGap(a: b, b: a), const Duration(minutes: 15));
  });

  test('toHijri returns a HijriCalendar with sane bounds', () {
    final h = toHijri(DateTime(2026, 7, 12));
    expect(h.hYear, greaterThan(1400));
    expect(h.hMonth, inInclusiveRange(1, 12));
    expect(h.hDay, inInclusiveRange(1, 30));
  });
}
