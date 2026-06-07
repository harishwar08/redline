import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs.dart';
import '../domain/livery.dart';

/// Holds the active livery and persists the choice. Watching this provider and
/// reading [Livery.accent] is how the whole app re-skins (the theme and the
/// gauge both depend on it).
class LiveryController extends Notifier<Livery> {
  @override
  Livery build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return Liveries.byId(prefs.getString(PrefKeys.livery));
  }

  Future<void> select(Livery livery) async {
    state = livery;
    await ref.read(sharedPrefsProvider).setString(PrefKeys.livery, livery.id);
  }
}

final liveryControllerProvider =
    NotifierProvider<LiveryController, Livery>(LiveryController.new);

/// Convenience: the current accent colour.
final accentProvider = Provider((ref) => ref.watch(liveryControllerProvider).accent);
