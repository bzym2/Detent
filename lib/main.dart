import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app_controller.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final controller = DetentController();
  await controller.boot();
  final preview = Platform.environment['DETENT_PREVIEW'] == '1';
  const options = WindowOptions(
    size: Size(440, 640),
    center: true,
    title: 'Detent',
  );
  unawaited(
    windowManager.waitUntilReadyToShow(options, () async {
      if (preview) {
        await windowManager.show();
        await windowManager.focus();
      } else {
        await windowManager.hide();
      }
    }),
  );
  runApp(DetentApp(controller: controller));
}
