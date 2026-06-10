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
import 'package:redline/features/profile/presentation/driver_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

/// Reproduces the Profile-edit crash: open the credential card's edit dialog and
/// focus/type in the Name field (the reported trigger of `_dependents.isEmpty`).
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('edit profile: open dialog + focus name field without throwing',
      (tester) async {
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
      child: const MaterialApp(home: DriverScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('DRIVER'), findsOneWidget); // credential card present
    expect(tester.takeException(), isNull);

    // Open the edit dialog via the pencil.
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Focus + type in the first field (Name) — the reported crash point.
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Ayrton');
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Save (disposes controllers after pop).
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
