import 'package:flutter/foundation.dart';

/// Timer + sound settings. Stored as the `settings` map inside `users/{uid}`
/// (and may be mirrored to shared_preferences for instant local reads).
///
/// [autoStart] is preserved from the existing timer behavior — it isn't in the
/// base spec schema but is kept so the timer doesn't lose a setting.
@immutable
class AppSettings {
  const AppSettings({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.lapsPerLongBreak = 4,
    this.soundsEnabled = true,
    this.autoStart = true,
  });

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int lapsPerLongBreak;
  final bool soundsEnabled;
  final bool autoStart;

  AppSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? lapsPerLongBreak,
    bool? soundsEnabled,
    bool? autoStart,
  }) =>
      AppSettings(
        focusMinutes: focusMinutes ?? this.focusMinutes,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
        lapsPerLongBreak: lapsPerLongBreak ?? this.lapsPerLongBreak,
        soundsEnabled: soundsEnabled ?? this.soundsEnabled,
        autoStart: autoStart ?? this.autoStart,
      );

  factory AppSettings.fromMap(Map<String, dynamic> d) => AppSettings(
        focusMinutes: (d['focusMinutes'] as num?)?.toInt() ?? 25,
        shortBreakMinutes: (d['shortBreakMinutes'] as num?)?.toInt() ?? 5,
        longBreakMinutes: (d['longBreakMinutes'] as num?)?.toInt() ?? 15,
        lapsPerLongBreak: (d['lapsPerLongBreak'] as num?)?.toInt() ?? 4,
        soundsEnabled: d['soundsEnabled'] as bool? ?? true,
        autoStart: d['autoStart'] as bool? ?? true,
      );

  /// Firestore map (also valid plain JSON — no date fields).
  Map<String, dynamic> toMap() => {
        'focusMinutes': focusMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'lapsPerLongBreak': lapsPerLongBreak,
        'soundsEnabled': soundsEnabled,
        'autoStart': autoStart,
      };

  Map<String, dynamic> toJson() => toMap();

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings.fromMap(j);
}
