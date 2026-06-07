import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/features/laplog/data/lap.dart';
import 'package:redline/features/laplog/data/lap_repository.dart';
import 'package:redline/features/profile/data/driver_profile.dart';
import 'package:redline/features/profile/data/profile_repository.dart';
import 'package:redline/features/settings/data/app_settings.dart';
import 'package:redline/features/settings/data/settings_repository.dart';
import 'package:redline/features/tasks/data/stint_repository.dart';

void main() {
  group('StintRepository', () {
    test('add appends in order; watch streams ordered list', () async {
      final repo = FirestoreStintRepository(FakeFirebaseFirestore(), 'u1');
      final a = await repo.addStint('Alpha');
      final b = await repo.addStint('Bravo');
      expect(a.order, 0);
      expect(b.order, 1);

      final stints = await repo.watchStints().first;
      expect(stints.map((s) => s.title), ['Alpha', 'Bravo']);
    });

    test('incrementLaps auto-completes at target; setDone toggles', () async {
      final repo = FirestoreStintRepository(FakeFirebaseFirestore(), 'u1');
      final s = await repo.addStint('Draft');
      await repo.updateStint(s.copyWith(targetLaps: 2));

      await repo.incrementLaps(s.id); // 1/2 → not done
      var cur = (await repo.watchStints().first).single;
      expect(cur.completedLaps, 1);
      expect(cur.isDone, isFalse);

      await repo.incrementLaps(s.id); // 2/2 → done
      cur = (await repo.watchStints().first).single;
      expect(cur.completedLaps, 2);
      expect(cur.isDone, isTrue);

      await repo.setDone(s.id, false); // reopen
      cur = (await repo.watchStints().first).single;
      expect(cur.isDone, isFalse);
    });

    test('delete removes; reorder rewrites order', () async {
      final repo = FirestoreStintRepository(FakeFirebaseFirestore(), 'u1');
      final a = await repo.addStint('A');
      final b = await repo.addStint('B');
      final c = await repo.addStint('C');

      await repo.deleteStint(b.id);
      expect((await repo.watchStints().first).map((s) => s.title), ['A', 'C']);

      await repo.reorder([c.id, a.id]);
      expect((await repo.watchStints().first).map((s) => s.title), ['C', 'A']);
    });

    test('repositories are isolated per uid', () async {
      final db = FakeFirebaseFirestore();
      await FirestoreStintRepository(db, 'u1').addStint('mine');
      final otherStints = await FirestoreStintRepository(db, 'u2').watchStints().first;
      expect(otherStints, isEmpty);
    });
  });

  group('LapRepository', () {
    Lap lapAt(DateTime started, {LapType type = LapType.focus}) => Lap(
          id: '',
          stintId: 's1',
          startedAt: started,
          endedAt: started.add(const Duration(minutes: 25)),
          durationSeconds: 1500,
          type: type,
          dateKey:
              '${started.year}-${started.month.toString().padLeft(2, '0')}-${started.day.toString().padLeft(2, '0')}',
        );

    test('addLap + watchAllLaps (newest first)', () async {
      final repo = FirestoreLapRepository(FakeFirebaseFirestore(), 'u1');
      final older = DateTime(2026, 6, 1, 9);
      final newer = DateTime(2026, 6, 5, 9);
      await repo.addLap(lapAt(older));
      await repo.addLap(lapAt(newer));

      final all = await repo.watchAllLaps().first;
      expect(all.length, 2);
      expect(all.first.startedAt, newer); // descending
      expect(all.last.startedAt, older);
    });

    test('watchLaps filters by startedAt range', () async {
      final repo = FirestoreLapRepository(FakeFirebaseFirestore(), 'u1');
      await repo.addLap(lapAt(DateTime(2026, 6, 1, 9)));
      await repo.addLap(lapAt(DateTime(2026, 6, 10, 9)));

      final inRange = await repo
          .watchLaps(from: DateTime(2026, 6, 5), to: DateTime(2026, 6, 15))
          .first;
      expect(inRange.length, 1);
      expect(inRange.single.startedAt, DateTime(2026, 6, 10, 9));
    });
  });

  group('ProfileRepository', () {
    test('watch emits null until upsert, then the profile', () async {
      final repo = FirestoreProfileRepository(FakeFirebaseFirestore(), 'u1');
      expect(await repo.watchProfile().first, isNull);

      await repo.upsertProfile(DriverProfile(createdAt: DateTime(2026), name: 'Senna', number: 12));
      final p = await repo.watchProfile().first;
      expect(p?.name, 'Senna');
      expect(p?.number, 12);
    });
  });

  group('SettingsRepository', () {
    test('watch emits defaults until set, then the saved settings', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreSettingsRepository(db, 'u1');
      expect((await repo.watchSettings().first).focusMinutes, 25); // default

      await repo.updateSettings(const AppSettings(focusMinutes: 50, soundsEnabled: false));
      final s = await repo.watchSettings().first;
      expect(s.focusMinutes, 50);
      expect(s.soundsEnabled, isFalse);
    });

    test('profile and settings coexist in the same user doc', () async {
      final db = FakeFirebaseFirestore();
      final profiles = FirestoreProfileRepository(db, 'u1');
      final settings = FirestoreSettingsRepository(db, 'u1');

      await profiles.upsertProfile(DriverProfile(createdAt: DateTime(2026), name: 'Lauda'));
      await settings.updateSettings(const AppSettings(focusMinutes: 30));

      expect((await profiles.watchProfile().first)?.name, 'Lauda');
      expect((await settings.watchSettings().first).focusMinutes, 30);
    });
  });
}
