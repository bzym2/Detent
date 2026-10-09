import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'settings_store.dart';

class DetentApp extends StatelessWidget {
  const DetentApp({super.key, required this.controller});

  final DetentController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Detent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.standard,
        listTileTheme: const ListTileThemeData(
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          scrolledUnderElevation: 0,
        ),
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
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/logo.png',
                filterQuality: FilterQuality.high,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Detent'),
                Text(
                  '第 ${controller.index + 1} 档 · 指针速度 $speed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          body: ListView(
            children: [
              const Divider(height: 1),
              ListTile(
                title: Text(
                  '档位',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                subtitle: const Text('选择一档，立刻应用到系统指针速度'),
              ),
              for (var i = 0; i < controller.speeds.length; i++)
                RadioListTile<int>(
                  value: i,
                  groupValue: controller.index,
                  onChanged: (value) {
                    if (value != null) {
                      controller.applyIndex(value);
                    }
                  },
                  title: Text('第 ${i + 1} 档'),
                  secondary: Text(
                    '${controller.speeds[i]}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                title: Text(
                  '当前档的指针速度',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                trailing: Text(
                  '$speed',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Slider(
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '$speed',
                  value: speed.toDouble(),
                  onChanged: (value) =>
                      controller.setCurrentSpeed(value.round()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: OverflowBar(
                  spacing: 8,
                  overflowSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: controller.speeds.length < maxLevelCount
                          ? controller.addLevel
                          : null,
                      child: const Text('添加档位'),
                    ),
                    OutlinedButton(
                      onPressed: controller.speeds.length > minLevelCount
                          ? controller.removeCurrentLevel
                          : null,
                      child: const Text('删除当前档'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(
                  '启动',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              SwitchListTile(
                title: const Text('开机启动'),
                subtitle: const Text('登录 Windows 后自动打开 Detent'),
                value: controller.startWithWindows,
                onChanged: controller.setStartup,
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(
                  '快捷键',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                subtitle: Text(controller.hotkeyStatus()),
              ),
            ],
          ),
        );
      },
    );
  }
}
