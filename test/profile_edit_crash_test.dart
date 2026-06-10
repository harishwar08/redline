import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:redline/core/firestore_providers.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:redline/features/auth/data/app_user.dart';
import 'package:redline/features/profile/presentation/edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

/// Guards the Profile-edit controller lifecycle (the reported `_dependents.isEmpty`
/// crash): open the Edit Profile screen, focus/type the Name field, and Save —
/// all without throwing. The form now lives in [EditProfileScreen], which owns
/// its controllers (initState/dispose).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('edit profile: focus name field + save without throwing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository(initial: const AppUser(uid: 'u1', isAnonymous: false));
    addTearDown(auth.dispose);

    final router = GoRouter(
      initialLocation: '/edit',
      routes: [
        GoRoute(path: '/edit', builder: (_, _) => const EditProfileScreen(isOnboarding: true)),
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('APP HOME STUB'))),
      ],
    );
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(auth),
      firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
    ]);
    addTearDown(c.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Focus + type in the Name field — the reported crash point.
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Ayrton');
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Save (disposes controllers as the screen leaves) → into the app.
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();
    expect(find.text('APP HOME STUB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
