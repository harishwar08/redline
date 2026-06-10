import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics_service.dart';
import '../../../core/async_x.dart';
import '../../../core/error_reporter.dart';
import '../../../core/firestore_providers.dart';
import '../../../core/prefs.dart';
import '../../auth/application/auth_providers.dart';
import '../data/stint.dart';
import '../data/stint_repository.dart';

/// The stint repository, scoped to the signed-in user. Rebuilds if the uid
/// changes (e.g. after a data reset). Only read once a uid exists — consumers
/// guard on [uidProvider] first (the splash guarantees a uid before any data
/// screen renders).
final stintRepositoryProvider = Provider<StintRepository>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) {
    throw StateError('stintRepositoryProvider read before a uid exists');
  }
  return FirestoreStintRepository(ref.watch(firestoreProvider), uid);
});

/// The single shared stint list — watched by BOTH the Pit Board and the Cluster
/// so a created/selected/edited stint reflects everywhere. Emits `[]` until a
/// uid exists.
final stintsProvider = StreamProvider<List<Stint>>((ref) {
  final uid = ref.watch(uidProvider);
  if (uid == null) return Stream.value(const <Stint>[]);
  return ref.watch(stintRepositoryProvider).watchStints();
});

extension StintListX on List<Stint> {
  /// Open stints, **newest first** — a freshly added stint (highest `order`)
  /// sorts to the top of the Pit Board.
  List<Stint> get open =>
      where((s) => !s.isDone).toList()..sort((a, b) => b.order.compareTo(a.order));
  List<Stint> get done => where((s) => s.isDone).toList();
}

/// The locally-selected "loaded" stint id — a UI selection, not a backend write.
/// Persisted so the loaded stint survives a restart.
class ActiveStintIdNotifier extends Notifier<String?> {
  @override
  String? build() => ref.read(sharedPrefsProvider).getString(PrefKeys.activeTaskId);

  void set(String id) {
    state = id;
    ref.read(sharedPrefsProvider).setString(PrefKeys.activeTaskId, id);
  }

  void clear() {
    state = null;
    ref.read(sharedPrefsProvider).remove(PrefKeys.activeTaskId);
  }
}

final activeStintIdProvider =
    NotifierProvider<ActiveStintIdNotifier, String?>(ActiveStintIdNotifier.new);

/// The loaded [Stint] (or null) resolved from the shared id + the stint list.
/// The Cluster's NOW DRIVING card watches this.
final activeStintProvider = Provider<Stint?>((ref) {
  final id = ref.watch(activeStintIdProvider);
  if (id == null) return null;
  for (final s in ref.watch(stintsProvider).dataOrNull ?? const <Stint>[]) {
    if (s.id == id) return s;
  }
  return null;
});

/// Mutations funnel through here so call sites stay clean and there is a single
/// place to harden error handling (Phase 7: Crashlytics + snackbar). All writes
/// are fire-and-forget — Firestore's offline cache updates [stintsProvider]
/// optimistically, so the UI reflects changes instantly.
class StintActions {
  StintActions(this._ref);
  final Ref _ref;

  StintRepository get _repo => _ref.read(stintRepositoryProvider);

  Future<void> add(String title) => _guard(() async {
        await _repo.addStint(title);
        _ref.read(analyticsServiceProvider).stintCreated();
      }, "Couldn't add the stint.");

  Future<void> rename(Stint s, String title) {
    final t = title.trim();
    return _guard(
        () => _repo.updateStint(s.copyWith(title: t.isEmpty ? s.title : t)), "Couldn't rename the stint.");
  }

  Future<void> setNotes(Stint s, String notes) =>
      _guard(() => _repo.updateStint(s.copyWith(notes: notes)), "Couldn't save your notes.");

  Future<void> setTargetLaps(Stint s, int laps) => _guard(
      () => _repo.updateStint(s.copyWith(targetLaps: laps.clamp(1, 99))), "Couldn't update the lap target.");

  Future<void> toggleDone(Stint s) =>
      _guard(() => _repo.setDone(s.id, !s.isDone), "Couldn't update the stint.");

  Future<void> delete(String id) {
    if (_ref.read(activeStintIdProvider) == id) {
      _ref.read(activeStintIdProvider.notifier).clear();
    }
    return _guard(() => _repo.deleteStint(id), "Couldn't delete the stint.");
  }

  void load(String id) => _ref.read(activeStintIdProvider.notifier).set(id);
  void unload() => _ref.read(activeStintIdProvider.notifier).clear();

  /// Runs [op], routing any failure to Crashlytics + a brief snackbar. A write
  /// failure must never crash the UI (and offline writes simply queue).
  Future<void> _guard(Future<void> Function() op, String userMessage) async {
    try {
      await op();
    } catch (e, st) {
      _ref.read(errorReporterProvider).report(e, st, reason: 'stint write', userMessage: userMessage);
    }
  }
}

final stintActionsProvider = Provider<StintActions>((ref) => StintActions(ref));
