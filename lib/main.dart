import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app_controller.dart';
import 'settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  final controller = DetentController();
  await controller.boot();
  const options = WindowOptions(
    size: Size(440, 680),
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
class DetentApp extends StatelessWidget {
  const DetentApp({super.key, required this.controller});

  final DetentController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          dynamicSchemeVariant: DynamicSchemeVariant.expressive,
        ),
        useMaterial3: true,
      ),
      home: DetentHome(controller: controller),
    );
  }
}

class DetentHome extends StatelessWidget {
  const DetentHome({super.key, required this.controller});

  final DetentController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final speed = controller.speeds[controller.index];
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detent', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('第 ${controller.index + 1} 档，系统指针速度 $speed'),
                const SizedBox(height: 4),
                Text(controller.hotkeyStatus()),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: controller.speeds.length,
                    itemBuilder: (context, i) {
                      return ListTile(
                        selected: i == controller.index,
                        title: Text('第 ${i + 1} 档'),
                        subtitle: Text('速度 ${controller.speeds[i]}'),
                        onTap: () => controller.applyIndex(i),
                      );
                    },
                  ),
                ),
                const Text('当前档的指针速度'),
                Slider(
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '$speed',
                  value: speed.toDouble(),
                  onChanged: (value) => controller.setCurrentSpeed(value.round()),
                ),
                Row(
                  children: [
                    FilledButton(
                      onPressed: controller.speeds.length < maxLevelCount
                          ? controller.addLevel
                          : null,
                      child: const Text('添加档位'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: controller.speeds.length > minLevelCount
                          ? controller.removeCurrentLevel
                          : null,
                      child: const Text('删除当前档'),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('开机启动'),
                  value: controller.startWithWindows,
                  onChanged: controller.setStartup,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
