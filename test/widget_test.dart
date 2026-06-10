import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/app/redline_app.dart';
import 'package:redline/core/firestore_providers.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  testWidgets('REDLINE boots guest-first: splash → straight into the Cluster',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        ],
        child: const RedlineApp(),
      ),
    );

    // The brand mark shows on the cold-start splash.
    expect(find.text('REDLINE'), findsOneWidget);

    // Guest-first: after the splash beat (~1.1s) the app navigates straight to
    // the Cluster (no auth wall). Pump through the page transition too.
    await tester.pump(const Duration(milliseconds: 1300)); // splash beat → nav
    await tester.pump(const Duration(milliseconds: 800)); // finish route transition
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('REDLINE'), findsNothing); // left the splash
    // With no loaded task, the Cluster card shows the empty state.
    expect(find.text('NO TASK LOADED'), findsOneWidget);
  });
}
