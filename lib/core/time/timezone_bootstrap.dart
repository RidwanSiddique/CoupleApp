import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Loads the IANA timezone database. Call once at app startup.
Future<void> initTimezones() async {
  tzdata.initializeTimeZones();
}

/// Returns the location for an IANA tz string, falling back to UTC.
tz.Location locationOrUtc(String iana) {
  try {
    return tz.getLocation(iana);
  } catch (_) {
    return tz.UTC;
  }
}
