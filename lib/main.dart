import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'data/house_store.dart';
import 'data/house_sync.dart';
import 'data/notifications.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

final houseStore = HouseStore();
final houseSync = HouseSync(houseStore);
Timer? _resyncDebounce;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final glassReady = LiquidGlassWidgets.initialize(
    enablePerformanceMonitor: false,
  );
  await Hive.initFlutter();
  await houseStore.init();
  await glassReady;
  houseStore.cloudReconnect = houseSync.start;
  houseStore.cloudStop = houseSync.stop;
  runApp(
    LiquidGlassWidgets.wrap(
      child: const HouseApp(),
      brightnessResolver: Theme.maybeBrightnessOf,
      adaptiveQuality: true,
      theme: GlassThemeData.simple(blur: 10, thickness: 30),
    ),
  );
  unawaited(_bootInBackground());
}

Future<void> _bootInBackground() async {
  if (houseStore.settings.hasHouse) {
    unawaited(houseSync.start());
  }
  await NotificationService.instance.init();
  await houseStore.scanPenalties();
  await NotificationService.instance.resync(houseStore);
  houseStore.addListener(_scheduleReminderResync);
}

void _scheduleReminderResync() {
  _resyncDebounce?.cancel();
  _resyncDebounce = Timer(const Duration(milliseconds: 400), () {
    NotificationService.instance.resync(houseStore);
  });
}

class HouseApp extends StatelessWidget {
  const HouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'House chores',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: HomeShell(store: houseStore, sync: houseSync),
    );
  }
}
