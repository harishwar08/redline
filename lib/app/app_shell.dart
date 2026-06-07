import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_system.dart';
import '../features/cluster/data/timer_controller.dart';
import '../features/garage/data/livery_controller.dart';
import '../features/laplog/application/lap_recorder.dart';
import '../features/tasks/application/stint_providers.dart';
import '../shared/services/accel_sound.dart';
import '../shared/services/notification_service.dart';
import '../shared/services/slam_sound.dart';
import '../shared/widgets/metal_tab_bar.dart';
import '../shared/widgets/screen_fx.dart';

/// The 5-tab… er, 4-tab app shell. The UI mockups use four destinations —
/// Cluster · Pit Board · Lap Log · Driver — with liveries living on the Driver
/// screen, so we follow the mockups rather than the flow doc's 5-tab list.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> with WidgetsBindingObserver {
  static const _tabs = <MetalTab>[
    MetalTab(icon: Icons.speed_rounded, label: 'Cluster'),
    MetalTab(icon: Icons.assignment_rounded, label: 'Pit Board'),
    MetalTab(icon: Icons.bar_chart_rounded, label: 'Lap Log'),
    MetalTab(icon: Icons.person_rounded, label: 'Driver'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Best-effort: prepare notifications and reconcile any session that ended
    // while the app was closed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).init();
      ref.read(slamSoundProvider).init(); // preload the car-slam SFX once
      ref.read(accelSoundProvider).init(); // preload the acceleration sweep sound

      // Warm the shared stint stream + restore the loaded stint, and activate
      // the lap recorder so completed sessions are logged (and stints credited)
      // regardless of which tab is open.
      ref.read(stintsProvider);
      ref.read(activeStintIdProvider);
      ref.read(lapRecorderProvider);
      ref.read(timerControllerProvider.notifier).reconcile();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(timerControllerProvider.notifier).reconcile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentProvider);
    final index = widget.navigationShell.currentIndex;
    // Cluster (tab 0) gets a slightly deeper nav surface than the other screens.
    final navBackground = index == 0 ? DS.navSurfaceCluster : DS.navSurface;
    return Scaffold(
      body: ScreenFx(child: widget.navigationShell),
      bottomNavigationBar: MetalTabBar(
        tabs: _tabs,
        currentIndex: index,
        accent: accent,
        background: navBackground,
        onTap: (i) => widget.navigationShell.goBranch(
          i,
          initialLocation: i == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}
