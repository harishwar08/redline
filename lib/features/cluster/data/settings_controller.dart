import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs.dart';
import '../domain/timer_models.dart';

/// Loads and persists [TimerSettings] (the Tuning Bay values).
class SettingsController extends Notifier<TimerSettings> {
  @override
  TimerSettings build() {
    final p = ref.watch(sharedPrefsProvider);
    return TimerSettings(
      focusMin: p.getInt(PrefKeys.focusMin) ?? 25,
      shortMin: p.getInt(PrefKeys.shortMin) ?? 5,
      longMin: p.getInt(PrefKeys.longMin) ?? 15,
      longBreakEvery: p.getInt(PrefKeys.longBreakEvery) ?? 4,
      autoStart: p.getBool(PrefKeys.autoStart) ?? true,
      soundOn: p.getBool(PrefKeys.soundOn) ?? true,
    );
  }

  Future<void> update(TimerSettings next) async {
    state = next;
    final p = ref.read(sharedPrefsProvider);
    await p.setInt(PrefKeys.focusMin, next.focusMin);
    await p.setInt(PrefKeys.shortMin, next.shortMin);
    await p.setInt(PrefKeys.longMin, next.longMin);
    await p.setInt(PrefKeys.longBreakEvery, next.longBreakEvery);
    await p.setBool(PrefKeys.autoStart, next.autoStart);
    await p.setBool(PrefKeys.soundOn, next.soundOn);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, TimerSettings>(SettingsController.new);
