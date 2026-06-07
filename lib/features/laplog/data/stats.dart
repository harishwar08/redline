import 'package:flutter/foundation.dart';

import '../../../core/format.dart';
import 'lap.dart';

/// Lifetime telemetry for the Driver dossier — derived entirely on-device from
/// the saved laps (no stored aggregates).
@immutable
class StatsSummary {
  const StatsSummary({
    this.totalFocusMin = 0,
    this.totalLaps = 0,
    this.pitVisits = 0,
    this.bestDayMin = 0,
    this.tasksFinished = 0,
    this.streak = 0,
  });

  final int totalFocusMin;
  final int totalLaps; // completed focus laps
  final int pitVisits; // completed breaks
  final int bestDayMin;
  final int tasksFinished;
  final int streak; // consecutive days (up to today) with ≥1 focus lap
}

/// A single bar in the Lap Log chart.
@immutable
class LapBar {
  const LapBar({required this.label, required this.minutes, this.highlight = false});
  final String label;
  final double minutes;
  final bool highlight;
}

enum LapRange { week, month }

/// The derived figures behind the Lap Log chart for a given range.
@immutable
class LapChartStats {
  const LapChartStats({
    required this.bars,
    required this.totalMinutes,
    required this.averageMinutes,
    required this.bestMinutes,
    required this.peakIndex,
  });

  final List<LapBar> bars;
  final double totalMinutes;
  final double averageMinutes; // mean over active buckets
  final double bestMinutes; // the tallest bucket
  final int peakIndex; // index of the peak bar, or -1

  bool get hasData => totalMinutes > 0;
}

/// Focus minutes per `YYYY-MM-DD`, summed from focus laps.
Map<String, int> focusMinutesByDay(List<Lap> laps) {
  final map = <String, int>{};
  for (final l in laps) {
    if (!l.isFocus) continue;
    map[l.dateKey] = (map[l.dateKey] ?? 0) + (l.durationSeconds ~/ 60);
  }
  return map;
}

DateTime _mondayOf(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

/// Seven daily bars for the current week (Mon–Sun).
List<LapBar> weekBars(List<Lap> laps, DateTime now) {
  final byDay = focusMinutesByDay(laps);
  final monday = _mondayOf(now);
  final todayKey = dateKey(now);
  return [
    for (var i = 0; i < 7; i++)
      () {
        final d = monday.add(Duration(days: i));
        final key = dateKey(d);
        return LapBar(
          label: weekdayLetter(d.weekday),
          minutes: (byDay[key] ?? 0).toDouble(),
          highlight: key == todayKey,
        );
      }(),
  ];
}

/// Six weekly bars (last six weeks); the peak week is highlighted.
List<LapBar> monthBars(List<Lap> laps, DateTime now) {
  final byDay = focusMinutesByDay(laps);
  final thisMonday = _mondayOf(now);
  final bars = <LapBar>[];
  var peak = 0.0;
  for (var w = 5; w >= 0; w--) {
    final weekStart = thisMonday.subtract(Duration(days: w * 7));
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += byDay[dateKey(weekStart.add(Duration(days: i)))] ?? 0;
    }
    peak = total > peak ? total.toDouble() : peak;
    bars.add(LapBar(label: '${weekStart.day}', minutes: total.toDouble()));
  }
  return [
    for (final b in bars)
      LapBar(label: b.label, minutes: b.minutes, highlight: b.minutes == peak && peak > 0),
  ];
}

/// Bars + totals/average/best/peak for the Lap Log chart, for [range].
LapChartStats chartStats(List<Lap> laps, LapRange range, DateTime now) {
  final bars = range == LapRange.week ? weekBars(laps, now) : monthBars(laps, now);
  final total = bars.fold<double>(0, (a, b) => a + b.minutes);
  final active = bars.where((b) => b.minutes > 0).toList();
  final avg = active.isEmpty ? 0.0 : total / active.length;
  final best = bars.fold<double>(0, (a, b) => b.minutes > a ? b.minutes : a);
  var peak = -1;
  for (var i = 0; i < bars.length; i++) {
    if (bars[i].minutes > 0 && bars[i].minutes >= best) peak = i;
  }
  return LapChartStats(
    bars: bars,
    totalMinutes: total,
    averageMinutes: avg,
    bestMinutes: best,
    peakIndex: peak,
  );
}

/// Compute the lifetime summary from all laps + the finished-stint count.
StatsSummary summarise(List<Lap> laps, int tasksFinished, DateTime now) {
  final byDay = focusMinutesByDay(laps);
  var totalFocus = 0, focusLaps = 0, pits = 0, best = 0;
  for (final l in laps) {
    if (l.isFocus) {
      totalFocus += l.durationSeconds ~/ 60;
      focusLaps++;
    } else {
      pits++;
    }
  }
  for (final m in byDay.values) {
    if (m > best) best = m;
  }

  // Streak: consecutive days back from today with focus minutes.
  var streak = 0;
  var cursor = DateTime(now.year, now.month, now.day);
  while ((byDay[dateKey(cursor)] ?? 0) > 0) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return StatsSummary(
    totalFocusMin: totalFocus,
    totalLaps: focusLaps,
    pitVisits: pits,
    bestDayMin: best,
    tasksFinished: tasksFinished,
    streak: streak,
  );
}
