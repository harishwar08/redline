import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/async_x.dart';
import '../../../core/design_system.dart';
import '../../../core/format.dart';
import '../../auth/application/auth_controller.dart';
import '../../laplog/application/stats_providers.dart';
import '../application/profile_photo.dart';
import '../application/profile_providers.dart';
import '../data/driver_profile.dart';

/// Driver HQ — the dossier: credential (or the sign-up/sign-in prompt for
/// guests), lifetime telemetry, and the Settings entry. The profile card is the
/// app's auth entry point.
class DriverScreen extends ConsumerWidget {
  const DriverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(isAuthenticatedProvider);
    final profile = ref.watch(profileProvider).dataOrNull ??
        DriverProfile(createdAt: DateTime.fromMillisecondsSinceEpoch(0));
    final photoPath = ref.watch(profilePhotoProvider);
    final stats = ref.watch(statsSummaryProvider);

    return DsBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DS.s17),
          children: [
            // ── Credential (authed) · or the auth entry prompt (guest) ──────
            if (authed)
              _credentialCard(context, ref, profile, photoPath)
            else
              _GuestPrompt(onTap: () => context.push('/sign-in')),
            const SizedBox(height: DS.s24),

            // ── Lifetime stats (zeros for guests) ────────────────────────
            const Text('Lifetime Stats', style: DSText.sectionLabel),
            const SizedBox(height: DS.s12),
            Row(
              children: [
                _Tele(label: 'Streak', value: '${stats.streak}', unit: 'd', valueColor: DS.accent),
                const SizedBox(width: DS.s12),
                _Tele(label: 'Total Hours', value: formatDuration(stats.totalFocusMin)),
              ],
            ),
            const SizedBox(height: DS.s12),
            Row(
              children: [
                _Tele(label: 'Tasks', value: '${stats.tasksFinished}'),
                const SizedBox(width: DS.s12),
                _Tele(label: 'Laps', value: '${stats.totalLaps}'),
              ],
            ),
            const SizedBox(height: DS.s24),

            // ── Settings — utility nav row ──────────────────────────────
            _UtilityRow(
              label: 'SETTINGS',
              onTap: () => context.push('/settings'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(WidgetRef ref) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked != null) {
      await ref.read(profilePhotoProvider.notifier).set(picked.path);
    }
  }

  Widget _credentialCard(
      BuildContext context, WidgetRef ref, DriverProfile profile, String? photoPath) {
    final sex = profile.sex == 'male'
        ? 'Male'
        : profile.sex == 'female'
            ? 'Female'
            : '—';
    // Bigger, more prominent — the whole card opens the edit form; the avatar
    // taps through to the photo picker instead.
    return DecoratedBox(
      decoration: DS.cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DS.rCard),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => _editProfile(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(DS.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Avatar(
                        photoPath: photoPath,
                        name: profile.name,
                        size: 68,
                        onTap: () => _pickPhoto(ref),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DRIVER', style: DSText.sectionLabel),
                            const SizedBox(height: 6),
                            Text(profile.name,
                                style: DSText.statValue.copyWith(fontSize: 26),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined, color: DS.textSecondary, size: 22),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, thickness: 1, color: DS.hairline),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _Meta(label: 'AGE', value: profile.age > 0 ? '${profile.age}' : '—'),
                      _Meta(label: 'SEX', value: sex),
                      _Meta(label: 'CAR NO', value: profile.number > 0 ? '${profile.number}' : '—'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _editProfile(BuildContext context, WidgetRef ref) {
    // The full Edit Profile screen (shared with the post-sign-up onboarding
    // step). Pushed so Save → pop returns here to the Profile tab.
    context.push('/edit-profile');
  }
}

/// The auth entry point shown to guests in place of the credential — a tappable
/// card that opens the Sign In screen by default (which links to Sign Up).
class _GuestPrompt extends StatelessWidget {
  const _GuestPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: DS.cardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DS.rCard),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DS.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1, color: DS.accent, size: 26),
                  ),
                  const SizedBox(width: DS.s17),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sign Up or Sign In', style: DSText.cardTitle),
                        SizedBox(height: DS.s4),
                        Text(
                          'Create an account to save your stints and stats',
                          style: DSText.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DS.s8),
                  const Icon(Icons.chevron_right, color: DS.textSecondary, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular profile avatar — the chosen photo, or initials when none is set.
/// Tapping it opens the photo picker. A small camera badge hints the action.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoPath,
    required this.name,
    required this.onTap,
    this.size = 56,
  });

  final String? photoPath;
  final String name;
  final VoidCallback onTap;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _initialsLabel() => Center(
        child: Text(_initials,
            style: DSText.statValue.copyWith(fontSize: size * 0.36, color: DS.accent)),
      );

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty && File(photoPath!).existsSync();
    return Semantics(
      button: true,
      label: 'Change profile photo',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.accent.withValues(alpha: 0.12),
                border: Border.all(color: DS.hairline, width: 1.5),
              ),
              child: hasPhoto
                  ? Image.file(File(photoPath!),
                      width: size, height: size, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _initialsLabel())
                  : _initialsLabel(),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.34,
                height: size * 0.34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DS.accent,
                  border: Border.all(color: DS.card, width: 2),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: size * 0.16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small labelled value used on the credential card (AGE / PHONE / CAR NO).
class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DSText.metricLabel),
          const SizedBox(height: 4),
          Text(value,
              style: DSText.body.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _Tele extends StatelessWidget {
  const _Tele({required this.label, required this.value, this.unit = '', this.valueColor = DS.textPrimary});
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(DS.s24),
        decoration: DS.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: DSText.metricLabel),
            const SizedBox(height: DS.s8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  text: value,
                  style: DSText.statValue.copyWith(color: valueColor),
                  children: unit.isEmpty
                      ? null
                      : [
                          TextSpan(
                            text: ' $unit',
                            style: const TextStyle(
                                fontFamily: DS.fontFamily,
                                color: DS.textTertiary,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal),
                          ),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width utility nav row — reads as a list row, not a button.
class _UtilityRow extends StatelessWidget {
  const _UtilityRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: DS.cardDecoration(), // soft drop-shadow (not clipped)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DS.rCard),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DS.s18, horizontal: DS.s18),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(label, style: DSText.captionStrong),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.chevron_right, color: DS.textSecondary, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
