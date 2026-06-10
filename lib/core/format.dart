// Time / number formatting helpers used across the gauge, Lap Log and
// telemetry. Kept pure (no Flutter imports) so they're trivially testable.

/// `mm:ss` for the odometer readout, e.g. 1505s → "25:05". Clamps negatives.
String formatClock(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final m = s ~/ 60;
  final sec = s % 60;
  return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

/// "03/05" lap progress.
String formatLaps(int done, int target) =>
    '${done.toString().padLeft(2, '0')}/${target.toString().padLeft(2, '0')}';

const _cardMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Task-card date as `06 June` — zero-padded day + full month name.
String formatCardDate(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_cardMonths[d.month - 1]}';

/// Focus minutes rendered as the "distance" odometer in km
/// (1 min ≈ 0.1 km — a playful, stable mapping for the telemetry tiles).
double minutesToKm(int minutes) => minutes * 0.1;

String formatKm(int minutes) => '${minutesToKm(minutes).toStringAsFixed(1)} km';

/// Human label for a focus minutes total, e.g. 418 → "6h 58m", 45 → "45m".
String formatDuration(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

/// `H:MM` hours readout from a focus-minutes total, e.g. 300 → "5:00",
/// 75 → "1:15", 0 → "0:00". Used by the Lap Log stat cards (rendered "5:00 hr").
String formatHoursMinutes(num minutes) {
  final total = minutes.round();
  final h = total ~/ 60;
  final m = total % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}

/// `YYYY-MM-DD` key for a date (the schema's `date` field, local time).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Single-letter weekday for the Lap Log axis (Mon=M … Sun=S).
String weekdayLetter(int weekday) {
  const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return letters[(weekday - 1) % 7];
}
