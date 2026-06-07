import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redline/app/redline_app.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/application/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  testWidgets('REDLINE boots to the splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: const RedlineApp(),
      ),
    );

    // The brand mark shows on the cold-start splash.
    expect(find.text('REDLINE'), findsOneWidget);

    // Let the splash timer fire and the onboarding redirect settle.
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    expect(find.text('Focus is just\ndriving with intent.'), findsOneWidget);
  });
}
