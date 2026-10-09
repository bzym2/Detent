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
    size: Size(1024, 640),
    minimumSize: Size(880, 560),
    center: true,
    title: 'Detent',
  );
  unawaited(
    windowManager.waitUntilReadyToShow(options, () async {
      try {
        await windowManager.setIcon('assets/logo.ico');
      } catch (_) {
        // Runner ICO still covers the executable icon.
      }
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
