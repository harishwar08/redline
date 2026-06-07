import '../data/lap.dart';
import '../data/stats.dart';

/// On-device stats engine. Holds a snapshot of the laps (+ the finished-stint
/// count) and derives every figure the Driver and Lap Log screens show — no
/// stored aggregates, recomputed whenever the underlying data changes.
class StatsService {
  const StatsService({required this.laps, required this.tasksFinished});

  final List<Lap> laps;
  final int tasksFinished;

  /// Lifetime telemetry: streak, total focus, pit visits, tasks finished, laps.
  StatsSummary summary([DateTime? now]) =>
      summarise(laps, tasksFinished, now ?? DateTime.now());

  /// The Lap Log chart figures for [range] (bars + total/average/best/peak).
  LapChartStats chart(LapRange range, [DateTime? now]) =>
      chartStats(laps, range, now ?? DateTime.now());
}
