import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error_reporter.dart';
import '../features/garage/data/livery_controller.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget. Watches the active livery so the entire app re-themes when the
/// driver picks a new racing colour in the Garage.
class RedlineApp extends ConsumerWidget {
  const RedlineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livery = ref.watch(liveryControllerProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'REDLINE',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: buildRedlineTheme(livery),
      routerConfig: router,
    );
  }
}
