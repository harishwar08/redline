import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session sound cues. Asset paths are wired but the files ship later (like the
/// fonts) — drop them into `assets/audio/`, declare them in `pubspec.yaml`, and
/// they play automatically. Until then every call degrades to silence.
enum Sfx { engineStart, lapComplete, pitIn, pitOut }

extension on Sfx {
  // Paths are relative to `assets/` for audioplayers' [AssetSource].
  String get asset => switch (this) {
        Sfx.engineStart => 'audio/engine_start.mp3',
        Sfx.lapComplete => 'audio/lap_complete.mp3',
        Sfx.pitIn => 'audio/pit_in.mp3',
        Sfx.pitOut => 'audio/pit_out.mp3',
      };
}

/// Thin, failure-tolerant wrapper around [AudioPlayer]. Never throws: if an
/// asset is missing or the platform can't play, it no-ops (Doc 03 error state).
class AudioService {
  AudioPlayer? _player;

  Future<void> play(Sfx sfx, {required bool enabled}) async {
    if (!enabled) return;
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource(sfx.asset));
    } catch (e) {
      // Asset not bundled yet / platform unsupported — stay silent.
      if (kDebugMode) debugPrint('AudioService: skipped ${sfx.asset} ($e)');
    }
  }

  void dispose() => _player?.dispose();
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
