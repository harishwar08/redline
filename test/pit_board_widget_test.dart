import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redline/core/firestore_providers.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';
import 'package:redline/features/tasks/application/stint_providers.dart';
import 'package:redline/features/tasks/presentation/pit_board_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

ProviderContainer _container(
  SharedPreferences prefs,
  FakeFirebaseFirestore db,
  FakeAuthRepository auth,
) =>
    ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(auth),
      firestoreProvider.overrideWithValue(db),
    ]);

Widget _host(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: PitBoardScreen())),
    );

FakeAuthRepository _seededAuth() =>
    FakeAuthRepository(initial: const AppUser(uid: 'u1', isAnonymous: true));

/// Drive a container's auth stream until a uid is available (so repos work).
Future<void> _awaitUid(ProviderContainer c) async {
  final ready = Completer<String>();
  final sub = c.listen<String?>(uidProvider, (_, uid) {
    if (uid != null && !ready.isCompleted) ready.complete(uid);
  }, fireImmediately: true);
  await ready.future.timeout(const Duration(seconds: 2));
  sub.close();
}

/// Pump the widget until it has a signed-in uid (auth stream settled).
Future<void> _pumpUntilSignedIn(WidgetTester tester, ProviderContainer c) async {
  for (var i = 0; i < 40 && c.read(uidProvider) == null; i++) {
    await tester.pump(const Duration(milliseconds: 25));
  }
}

/// Pump until [finder] matches (or timeout) — streams settle over a few frames.
Future<void> _pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _openModal(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Add task'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('"+" opens ADD TASK modal; ADD creates a stint and it streams in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _seededAuth();
    addTearDown(auth.dispose);
    final c = _container(prefs, FakeFirebaseFirestore(), auth);
    addTearDown(c.dispose);

    await tester.pumpWidget(_host(c));
    await _pumpUntilSignedIn(tester, c);
    await _pumpUntil(tester, find.text('GRID EMPTY'));
    expect(find.text('GRID EMPTY'), findsOneWidget);

    await _openModal(tester);
    expect(find.text('ADD TASK'), findsOneWidget);

    // Empty input is ignored; the modal stays open.
    await tester.tap(find.text('ADD'));
    await tester.pump();
    expect(find.text('ADD TASK'), findsOneWidget);

    // Real input creates the stint; it streams into the list.
    await tester.enterText(find.byType(TextField), 'Draft Q3 narrative');
    await tester.tap(find.text('ADD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // dialog dismiss
    await _pumpUntil(tester, find.text('Draft Q3 narrative'));
    expect(find.text('Draft Q3 narrative'), findsOneWidget);

    // Tapping the row loads it as the active stint.
    await tester.tap(find.text('Draft Q3 narrative'));
    await tester.pump();
    expect(c.read(activeStintIdProvider), isNotNull);
  });

  testWidgets('keyboard "done" inside the modal also adds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _seededAuth();
    addTearDown(auth.dispose);
    final c = _container(prefs, FakeFirebaseFirestore(), auth);
    addTearDown(c.dispose);

    await tester.pumpWidget(_host(c));
    await _pumpUntilSignedIn(tester, c);
    await _openModal(tester);

    await tester.enterText(find.byType(TextField), 'Inbox to zero');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _pumpUntil(tester, find.text('Inbox to zero'));
    expect(find.text('Inbox to zero'), findsOneWidget);
  });

  testWidgets('whitespace-only input is rejected', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = _seededAuth();
    addTearDown(auth.dispose);
    final c = _container(prefs, FakeFirebaseFirestore(), auth);
    addTearDown(c.dispose);

    await tester.pumpWidget(_host(c));
    await _pumpUntilSignedIn(tester, c);
    await _openModal(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('ADD'));
    await tester.pump();
    expect(find.text('ADD TASK'), findsOneWidget); // still open, nothing added
  });

  test('the loaded stint id persists across a relaunch (shared store)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = FakeFirebaseFirestore();

    // Launch 1: create a stint and load it.
    final auth1 = _seededAuth();
    final c1 = _container(prefs, db, auth1);
    await _awaitUid(c1);
    final stint = await c1.read(stintRepositoryProvider).addStint('Morning planning');
    c1.read(activeStintIdProvider.notifier).set(stint.id);
    auth1.dispose();
    c1.dispose();

    // Launch 2: same prefs + same store + same uid.
    final auth2 = _seededAuth();
    final c2 = _container(prefs, db, auth2);
    addTearDown(auth2.dispose);
    addTearDown(c2.dispose);
    await _awaitUid(c2);

    expect(c2.read(activeStintIdProvider), stint.id); // persisted locally
    final stints = await c2.read(stintRepositoryProvider).watchStints().first;
    expect(stints.any((s) => s.id == stint.id && s.title == 'Morning planning'), isTrue);
  });
}
