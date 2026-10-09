import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app_controller.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final controller = DetentController();
  await controller.boot();
  const options = WindowOptions(
    size: Size(420, 560),
    center: true,
    title: 'Detent',
  );
  unawaited(
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.hide();
    }),
  );
  runApp(DetentApp(controller: controller));
}
