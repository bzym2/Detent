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
            title: const Text('Detent'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '第 ${controller.index + 1} 档 · 指针速度 $speed',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 260,
                child: Material(
                  color: theme.colorScheme.surfaceContainerLowest,
                  child: ListView(
                    children: [
                      ListTile(
                        title: Text(
                          '档位',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        subtitle: const Text('选择一档立刻生效'),
                      ),
                      const Divider(height: 1),
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
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '当前档的指针速度',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      trailing: Text(
                        '$speed',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    Slider(
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: '$speed',
                      value: speed.toDouble(),
                      onChanged: (value) =>
                          controller.setCurrentSpeed(value.round()),
                    ),
                    OverflowBar(
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
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('开机启动'),
                      subtitle: const Text('登录 Windows 后自动打开 Detent'),
                      value: controller.startWithWindows,
                      onChanged: controller.setStartup,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
