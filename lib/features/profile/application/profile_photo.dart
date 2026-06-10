import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/prefs.dart';

/// The driver's profile-photo file path (or null). Stored locally in
/// shared_preferences for now — a note for the backend phase: move the actual
/// image to backend storage and keep just a URL/ref here.
class ProfilePhotoController extends Notifier<String?> {
  @override
  String? build() => ref.read(sharedPrefsProvider).getString(PrefKeys.profilePhotoPath);

  Future<void> set(String path) async {
    state = path;
    await ref.read(sharedPrefsProvider).setString(PrefKeys.profilePhotoPath, path);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPrefsProvider).remove(PrefKeys.profilePhotoPath);
  }
}

final profilePhotoProvider =
    NotifierProvider<ProfilePhotoController, String?>(ProfilePhotoController.new);
