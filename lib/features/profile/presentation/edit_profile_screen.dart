import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/async_x.dart';
import '../../../core/design_system.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profile_providers.dart';
import '../data/driver_profile.dart';

/// Edit Profile — the credential form (name, sex, age, car number), shown as a
/// full screen. **Context-aware** via [isOnboarding]:
///
/// - Reached as the post-sign-up step ([isOnboarding] true): pre-filled with the
///   account's name + email; **Save** routes into the app (Drive).
/// - Reached normally from the Profile tab ([isOnboarding] false): **Save**
///   returns to Profile (pop), and a back arrow cancels.
///
/// Owns its [TextEditingController]s (initState/dispose) for a safe lifecycle.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _number = TextEditingController();
  String _sex = '';
  bool _prefilled = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _number.dispose();
    super.dispose();
  }

  /// One-time pre-fill from the profile once it's available (the auth bootstrap
  /// writes name + email on sign-up). Guarded so it never clobbers edits.
  void _prefill(DriverProfile p) {
    if (_prefilled) return;
    _prefilled = true;
    _name.text = p.name;
    if (p.age > 0) _age.text = '${p.age}';
    if (p.number > 0) _number.text = '${p.number}'; // blank until the user sets one
    _sex = p.sex;
  }

  Future<void> _save() async {
    final base = ref.read(profileProvider).dataOrNull ?? DriverProfile(createdAt: DateTime.now());
    await ref.read(profileRepositoryProvider).upsertProfile(base.copyWith(
          name: _name.text.trim().isEmpty ? base.name : _name.text.trim(),
          age: int.tryParse(_age.text.trim()) ?? base.age,
          number: int.tryParse(_number.text) ?? base.number,
          sex: _sex,
        ));
    if (!mounted) return;
    // Context-aware exit: onboarding → into the app; normal edit → back to Profile.
    if (widget.isOnboarding) {
      context.go('/');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).dataOrNull;
    if (profile != null) _prefill(profile);
    final email = ref.watch(currentEmailProvider);

    return Scaffold(
      backgroundColor: DS.bgBase,
      body: DsBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header — back arrow (normal edit only) + title.
              Padding(
                padding: const EdgeInsets.fromLTRB(DS.s8, DS.s8, DS.s17, DS.s8),
                child: Row(
                  children: [
                    if (!widget.isOnboarding)
                      Semantics(
                        button: true,
                        label: 'Back',
                        child: InkResponse(
                          onTap: () => context.pop(),
                          radius: 24,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.arrow_back, color: DS.textPrimary, size: 26),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: DS.s8),
                    const SizedBox(width: DS.s4),
                    const Text('Edit Profile', style: DSText.screenTitle),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(DS.s17, DS.s8, DS.s17, DS.s24),
                  children: [
                    if (widget.isOnboarding) ...[
                      Text(
                        'Complete your profile to get started.',
                        style: DSText.body.copyWith(color: DS.textSecondary),
                      ),
                      const SizedBox(height: DS.s24),
                    ],
                    _field('Name', _name, keyboard: TextInputType.name),
                    const SizedBox(height: DS.s17),
                    _readOnlyField('Email', (email ?? '').isEmpty ? '—' : email!),
                    const SizedBox(height: DS.s17),
                    // Sex — Male / Female selector.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SEX', style: DSText.metricLabel),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SexChip(
                                label: 'Male',
                                selected: _sex == 'male',
                                onTap: () => setState(() => _sex = 'male'),
                              ),
                            ),
                            const SizedBox(width: DS.s12),
                            Expanded(
                              child: _SexChip(
                                label: 'Female',
                                selected: _sex == 'female',
                                onTap: () => setState(() => _sex = 'female'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: DS.s17),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _field('Age', _age, digitsOnly: true)),
                        const SizedBox(width: DS.s17),
                        Expanded(child: _field('Car No', _number, digitsOnly: true)),
                      ],
                    ),
                    const SizedBox(height: DS.s32),
                    _SaveButton(
                      label: widget.isOnboarding ? 'Save & Continue' : 'Save',
                      onTap: _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Design-system field — filled surface, hairline border, no Material underline.
  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType? keyboard,
    bool digitsOnly = false,
  }) {
    final formatters = <TextInputFormatter>[
      if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: DSText.metricLabel),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: DS.surfaceInput,
            borderRadius: BorderRadius.circular(DS.rInput),
            border: Border.all(color: DS.hairline),
          ),
          child: TextField(
            controller: c,
            keyboardType: keyboard ?? (digitsOnly ? TextInputType.number : null),
            inputFormatters: formatters.isEmpty ? null : formatters,
            cursorColor: DS.textPrimary,
            style: const TextStyle(
                fontFamily: DS.fontFamily, color: DS.textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
            decoration: const InputDecoration(
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  /// A read-only display field (the account email — not editable here).
  Widget _readOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: DSText.metricLabel),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: DS.surfaceInput,
            borderRadius: BorderRadius.circular(DS.rInput),
            border: Border.all(color: DS.hairline),
          ),
          child: Text(
            value,
            style: const TextStyle(
                fontFamily: DS.fontFamily, color: DS.textSecondary, fontSize: 16, fontWeight: FontWeight.w400),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// A selectable Male/Female chip.
class _SexChip extends StatelessWidget {
  const _SexChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? DS.accent : DS.surfaceInput,
          borderRadius: BorderRadius.circular(DS.rInput),
          border: Border.all(color: selected ? DS.accent : DS.hairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DS.fontFamily,
            color: selected ? Colors.white : DS.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Full-width accent Save button.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.label, required this.onTap});

  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: DS.accent,
          borderRadius: BorderRadius.circular(DS.rInput),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontFamily: DS.fontFamily, color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
