import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:redline/core/prefs.dart';
import 'package:redline/features/auth/presentation/sign_up_screen.dart';
import 'package:redline/features/auth/presentation/widgets/auth_buttons.dart';
import 'package:redline/features/auth/presentation/widgets/terms_checkbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sign Up screen: the terms-gated CTA, full validation, and the guest-first
/// post-success navigation into the app (the screen calls `go('/')` itself now
/// that there is no router redirect). Hosted in a minimal router so it doesn't
/// boot the whole app.
void main() {
  Future<void> pumpSignUp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/sign-up',
      routes: [
        GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
        GoRoute(path: '/sign-in', builder: (_, _) => const Scaffold(body: Text('SIGN IN STUB'))),
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('APP HOME STUB'))),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  testWidgets('CTA gated by valid form + terms, then enters the app on success',
      (tester) async {
    await pumpSignUp(tester);
    expect(find.text('Create your account and start tracking your performance'),
        findsOneWidget);

    PrimaryButton cta() => tester.widget<PrimaryButton>(find.byType(PrimaryButton));

    // Starts disabled (invalid form, terms unchecked).
    expect(cta().onPressed, isNull);

    // Fill a valid form: name, email, mobile, password, confirm.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Ada Lovelace');
    await tester.enterText(fields.at(1), 'ada@redline.app');
    await tester.enterText(fields.at(2), '+15551234567');
    await tester.enterText(fields.at(3), 'Passw0rd!');
    await tester.enterText(fields.at(4), 'Passw0rd!');
    await tester.pump();

    // Still gated until the terms box is checked.
    expect(cta().onPressed, isNull);

    final box = find
        .descendant(of: find.byType(TermsCheckbox), matching: find.byType(GestureDetector))
        .first;
    await tester.ensureVisible(box);
    await tester.tap(box);
    await tester.pump();
    expect(cta().onPressed, isNotNull);

    // Submit → loading (900ms) → authenticated → the screen navigates to '/'.
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump(); // loading
    await tester.pump(const Duration(milliseconds: 1100)); // resolve
    await tester.pumpAndSettle();

    expect(find.text('APP HOME STUB'), findsOneWidget);
  });
}
