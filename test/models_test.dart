import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/features/laplog/data/lap.dart';
import 'package:redline/features/profile/data/driver_profile.dart';
import 'package:redline/features/settings/data/app_settings.dart';
import 'package:redline/features/tasks/data/stint.dart';

void main() {
  // A whole-millisecond instant so Timestamp round-trips compare equal.
  final t = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  test('Stint: JSON round-trip, Firestore Timestamp, fromMap accepts both', () {
    final s = Stint(
      id: 's1',
      title: 'Draft Q3 narrative',
      createdAt: t,
      targetLaps: 3,
      completedLaps: 1,
      order: 2,
      notes: 'open with the movement',
    );

    final back = Stint.fromJson(s.toJson());
    expect(back.id, 's1');
    expect(back.title, 'Draft Q3 narrative');
    expect(back.createdAt, t);
    expect(back.targetLaps, 3);
    expect(back.completedLaps, 1);
    expect(back.isDone, false);
    expect(back.order, 2);
    expect(back.notes, 'open with the movement');
    expect(back.progress, closeTo(1 / 3, 1e-9));

    final fs = s.toFirestore();
    expect(fs['createdAt'], isA<Timestamp>());
    expect(fs.containsKey('id'), isFalse); // id is the doc key, not a field

    // fromMap reads the Firestore form (Timestamp) just as well as JSON (millis).
    final fromFs = Stint.fromMap('s1', fs);
    expect(fromFs.createdAt, t);
    expect(fromFs.title, 'Draft Q3 narrative');
  });

  test('Lap: JSON round-trip + type key + Firestore Timestamps', () {
    final lap = Lap(
      id: 'l1',
      stintId: 's1',
      startedAt: t,
      endedAt: t.add(const Duration(minutes: 25)),
      durationSeconds: 1500,
      type: LapType.pitStop,
      dateKey: '2026-06-07',
    );

    final back = Lap.fromJson(lap.toJson());
    expect(back.id, 'l1');
    expect(back.stintId, 's1');
    expect(back.durationSeconds, 1500);
    expect(back.type, LapType.pitStop);
    expect(back.isFocus, isFalse);
    expect(back.dateKey, '2026-06-07');
    expect(back.startedAt, t);

    final fs = lap.toFirestore();
    expect(fs['startedAt'], isA<Timestamp>());
    expect(fs['endedAt'], isA<Timestamp>());
    expect(fs['type'], 'pitStop');
    expect(Lap.fromMap('l1', fs).endedAt, t.add(const Duration(minutes: 25)));

    expect(LapType.fromKey('focus'), LapType.focus);
    expect(LapType.fromKey('pitStop'), LapType.pitStop);
    expect(LapType.fromKey(null), LapType.focus); // safe default
  });

  test('DriverProfile: JSON round-trip + Firestore Timestamp', () {
    final p = DriverProfile(
      createdAt: t,
      name: 'A. Senna',
      team: 'McLaren',
      country: 'BRA',
      number: 12,
      liveryColor: '#FF8000',
    );

    final back = DriverProfile.fromJson(p.toJson());
    expect(back.name, 'A. Senna');
    expect(back.team, 'McLaren');
    expect(back.country, 'BRA');
    expect(back.number, 12);
    expect(back.liveryColor, '#FF8000');
    expect(back.createdAt, t);

    expect(p.toMap()['createdAt'], isA<Timestamp>());
    expect(DriverProfile.fromMap(p.toMap()).createdAt, t);
  });

  test('AppSettings: round-trip + defaults', () {
    const s = AppSettings(
      focusMinutes: 50,
      shortBreakMinutes: 10,
      longBreakMinutes: 20,
      lapsPerLongBreak: 3,
      soundsEnabled: false,
      autoStart: false,
    );
    final back = AppSettings.fromJson(s.toJson());
    expect(back.focusMinutes, 50);
    expect(back.shortBreakMinutes, 10);
    expect(back.longBreakMinutes, 20);
    expect(back.lapsPerLongBreak, 3);
    expect(back.soundsEnabled, isFalse);
    expect(back.autoStart, isFalse);

    const defaults = AppSettings();
    expect(defaults.focusMinutes, 25);
    expect(defaults.lapsPerLongBreak, 4);
    expect(defaults.soundsEnabled, isTrue);
  });
}
