import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/prefs.dart';
import '../../../core/tokens.dart';
import '../../../core/typography.dart';
import '../../../shared/widgets/screen_fx.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/data/driver_profile.dart';

/// Driver Sign-In — issues a local "competition licence". No real auth in v1
/// (anonymous/guest); Phase 5 adds account + sync. Built out visually in
/// Phase 6; functional now so onboarding completes.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _name = TextEditingController(text: 'Valentina Rossi');
  final _number = TextEditingController(text: '27');
  final _nat = TextEditingController(text: 'ITA');

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _nat.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    final profile = DriverProfile(
      createdAt: DateTime.now(),
      name: _name.text.trim().isEmpty ? 'Privateer' : _name.text.trim(),
      number: int.tryParse(_number.text.trim()) ?? 27,
      country: _nat.text.trim().isEmpty ? 'ITA' : _nat.text.trim().toUpperCase(),
    );
    await ref.read(profileRepositoryProvider).upsertProfile(profile);
    await ref.read(sharedPrefsProvider).setBool(PrefKeys.onboarded, true);
    if (mounted) context.go('/');
  }

  Future<void> _later() async {
    await ref.read(sharedPrefsProvider).setBool(PrefKeys.onboarded, true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScreenFx(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(RSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: RSpace.xl),
                Center(
                  child: Text('FIA COMPETITION LICENCE',
                      style: RText.plateLabel(color: RColors.brassHi)),
                ),
                const SizedBox(height: RSpace.xs),
                Center(child: Text('DRIVER CREDENTIAL', style: RText.label(size: 12))),
                const SizedBox(height: RSpace.xl),
                _Field(label: 'Bonded Name', controller: _name),
                const SizedBox(height: RSpace.l),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Car No.',
                        controller: _number,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    const SizedBox(width: RSpace.l),
                    Expanded(child: _Field(label: 'Nationality', controller: _nat)),
                  ],
                ),
                const SizedBox(height: RSpace.huge),
                FilledButton(onPressed: _enter, child: const Text('ENTER THE GARAGE')),
                const SizedBox(height: RSpace.s),
                TextButton(
                  onPressed: _later,
                  child: Text('SIGN IN LATER',
                      style: RText.button(color: RColors.parchment)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: RText.plateLabel(color: RColors.parchment)),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: RColors.dashShadow,
            borderRadius: RRadii.rPlate,
            border: Border.all(color: RColors.line),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: AppFonts.numeral(size: 18, color: RColors.ivory),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
