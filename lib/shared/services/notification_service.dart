import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cluster/domain/timer_models.dart';

/// Fires a local notification when a session ends. Failure-tolerant: if the OS
/// denies permission or the platform is unsupported (web/tests), it no-ops and
/// the app falls back to its in-app banner (Doc 03).
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _initTried = false;
  bool granted = false;

  Future<void> init() async {
    if (_initTried || kIsWeb) return;
    _initTried = true;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );
      granted = await _requestPermission();
      _ready = true;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService: init failed ($e)');
    }
  }

  Future<bool> _requestPermission() async {
    try {
      final android =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
    } catch (_) {/* ignore */}
    return false;
  }

  Future<void> sessionComplete(TimerMode mode) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    if (!_ready || !granted) return;

    final (title, body) = switch (mode) {
      TimerMode.focus => ('Lap Completed', 'Take a break now.'),
      TimerMode.shortBreak => ('Break Over', "Break's over — start the race."),
      TimerMode.longBreak => ('REST OVER', "You've earned it. Next stint awaits."),
    };

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'redline_sessions',
        'Session alerts',
        channelDescription: 'Fires when a focus lap or break ends.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    try {
      await _plugin.show(id: 0, title: title, body: body, notificationDetails: details);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationService: show failed ($e)');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
