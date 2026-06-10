import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Car-acceleration sound synced to the gauge's rev-up sweep. Preloaded once at
/// init for an instant start; [start] fires the instant the needle begins
/// moving and runs in parallel, [stop] fades it out when the needle finishes.
/// Used ONLY for the startup sweep (never the countdown).
class AccelSound {
  static const _asset = 'audio/new-car-slam.mp3'; // needle rev-up sweep sound
  AudioPlayer? _player;
  bool _ready = false;
  bool _loading = false;
  Timer? _fade;

  Future<void> init() async {
    if (_ready || _loading || kIsWeb) return;
    _loading = true;
    try {
      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.stop);
      // Low-latency path (Android SoundPool) so the sweep sound starts the
      // instant the needle moves — the default MediaPlayer mode has a noticeable
      // start delay. Volume control (for the fade-out) still works in this mode.
      await _player!.setPlayerMode(PlayerMode.lowLatency);
      await _player!.setSource(AssetSource(_asset)); // preload into memory
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('AccelSound: init failed ($e)');
    } finally {
      _loading = false;
    }
  }

  /// Start (or restart) the acceleration sound from the top — instant, non-blocking.
  void start() {
    final p = _player;
    if (!_ready || p == null) return;
    _fade?.cancel();
    p.setVolume(1.0);
    p.seek(Duration.zero);
    p.resume();
  }

  /// Fade out over ~240ms then stop (so trimming it at the needle's end of
  /// travel doesn't click). If the clip already finished, this is a no-op.
  void stop() {
    final p = _player;
    if (!_ready || p == null) return;
    _fade?.cancel();
    var v = 1.0;
    _fade = Timer.periodic(const Duration(milliseconds: 40), (t) {
      v -= 0.17;
      if (v <= 0) {
        t.cancel();
        p.stop();
        p.setVolume(1.0);
      } else {
        p.setVolume(v);
      }
    });
  }

  void dispose() {
    _fade?.cancel();
    _player?.dispose();
  }
}

final accelSoundProvider = Provider<AccelSound>((ref) {
  final sound = AccelSound();
  ref.onDispose(sound.dispose);
  return sound;
});
