import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redline/core/firestore_providers.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_controller.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';
import 'package:redline/features/tasks/application/stint_providers.dart';
import 'package:redline/features/tasks/presentation/pit_board_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

/// Reproduces the `_dependents.isEmpty` crash: creating a task inserts it at the
/// top, reordering the list under stateful tiles. Without stable keys the tile
/// State/subtrees reassociate by index and the framework throws during teardown.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpUntilSignedIn(WidgetTester tester, ProviderContainer c) async {
    for (var i = 0; i < 40 && c.read(uidProvider) == null; i++) {
      await tester.pump(const Duration(milliseconds: 25));
    }
  }

  Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('creating tasks reorders the list without throwing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(initial: const AppUser(uid: 'u1', isAnonymous: true));
    addTearDown(auth.dispose);
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(auth),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
      isAuthenticatedProvider.overrideWithValue(true),
    ]);
    addTearDown(c.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: PitBoardScreen())),
    ));
    await pumpUntilSignedIn(tester, c);

    final repo = c.read(stintRepositoryProvider);
    await repo.addStint('Alpha');
    await pumpUntil(tester, find.text('Alpha'));
    expect(find.text('Alpha'), findsOneWidget);

    // Load Alpha (selected → white border, stateful tile holds hint state).
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    expect(c.read(activeStintIdProvider), isNotNull);

    // Create more — each inserts at the TOP, reordering the stateful tiles.
    await repo.addStint('Bravo');
    await pumpUntil(tester, find.text('Bravo'));
    await repo.addStint('Charlie');
    await pumpUntil(tester, find.text('Charlie'));
    await tester.pump(const Duration(milliseconds: 200));

    // The crash surfaces as an uncaught framework exception during the rebuild.
    expect(tester.takeException(), isNull);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });
}
