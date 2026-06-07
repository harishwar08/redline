import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Low-latency "car slam" SFX for the Cluster controls. A small pool of
/// preloaded [AudioPlayer]s in low-latency mode is created ONCE at init; each
/// press restarts the next player in the pool, so there's no file I/O on tap,
/// playback is instant, and rapid presses overlap.
class SlamSound {
  static const _asset = 'audio/car-slam.wav'; // resolves to assets/audio/car-slam.wav
  final List<AudioPlayer> _players = [];
  int _next = 0;
  bool _ready = false;
  bool _loading = false;

  Future<void> init() async {
    if (_ready || _loading || kIsWeb) return;
    _loading = true;
    try {
      for (var i = 0; i < 4; i++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setSource(AssetSource(_asset)); // preload into memory
        _players.add(p);
      }
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('SlamSound: init failed ($e)');
    } finally {
      _loading = false;
    }
  }

  /// Fire-and-forget: restarts the next pooled player instantly; non-blocking.
  void play() {
    if (!_ready || _players.isEmpty) return;
    final p = _players[_next];
    _next = (_next + 1) % _players.length;
    p.seek(Duration.zero);
    p.resume();
  }

  Future<void> dispose() async {
    for (final p in _players) {
      await p.dispose();
    }
  }
}

final slamSoundProvider = Provider<SlamSound>((ref) {
  final sound = SlamSound();
  ref.onDispose(sound.dispose);
  return sound;
});
