import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/async_x.dart';
import '../../tasks/application/stint_providers.dart';
import '../data/lap.dart';
import '../data/stats.dart';
import 'lap_providers.dart';
import 'stats_service.dart';

/// The stats engine, rebuilt whenever laps or stints change. Everything is
/// derived on-device from the laps stream — no stored aggregates.
final statsServiceProvider = Provider<StatsService>((ref) {
  final laps = ref.watch(lapsProvider).dataOrNull ?? const <Lap>[];
  final stints = ref.watch(stintsProvider).dataOrNull ?? const [];
  return StatsService(
    laps: laps,
    tasksFinished: stints.where((s) => s.isDone).length,
  );
});

/// Lifetime telemetry for the Driver dossier (Streak · Total hours · Tasks ·
/// Laps), recomputed reactively.
final statsSummaryProvider =
    Provider<StatsSummary>((ref) => ref.watch(statsServiceProvider).summary());
