import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';
import 'hotkey_service.dart';
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
        navigationRailTheme: const NavigationRailThemeData(
          labelType: NavigationRailLabelType.all,
        ),
      ),
      home: DetentHome(controller: controller),
    );
  }
}

class DetentHome extends StatefulWidget {
  const DetentHome({super.key, required this.controller});

  final DetentController controller;

  @override
  State<DetentHome> createState() => _DetentHomeState();
}

class _DetentHomeState extends State<DetentHome> {
  int _section = 0;
  late final TextEditingController _labelController;

  DetentController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: controller.levelTitle(controller.index),
    );
    controller.addListener(_syncLabelField);
  }

  void _syncLabelField() {
    final next = controller.levelTitle(controller.index);
    if (_labelController.text != next) {
      _labelController.text = next;
    }
  }

  @override
  void dispose() {
    controller.removeListener(_syncLabelField);
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final speed = controller.speeds[controller.index];
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _section,
                onDestinationSelected: (value) {
                  setState(() => _section = value);
                },
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/logo.png',
                        width: 40,
                        height: 40,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 8),
                      Text('Detent', style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune),
                    label: Text('档位'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.keyboard_outlined),
                    selectedIcon: Icon(Icons.keyboard),
                    label: Text('快捷键'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: Text('常规'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.info_outline),
                    selectedIcon: Icon(Icons.info),
                    label: Text('关于'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: switch (_section) {
                  0 => _LevelsPage(
                      controller: controller,
                      labelController: _labelController,
                      speed: speed,
                    ),
                  1 => _HotkeysPage(controller: controller),
                  2 => _GeneralPage(controller: controller),
                  _ => const _AboutPage(),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LevelsPage extends StatelessWidget {
  const _LevelsPage({
    required this.controller,
    required this.labelController,
    required this.speed,
  });

  final DetentController controller;
  final TextEditingController labelController;
  final int speed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 280,
          child: ListView(
            children: [
              ListTile(
                title: Text(
                  '档位列表',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                subtitle: Text('当前：${controller.levelTitle(controller.index)}'),
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
                  title: Text(controller.levelTitle(i)),
                  subtitle: Text('速度 ${controller.speeds[i]}'),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            children: [
              Text(
                '当前档',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: '档位名称',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onChanged: controller.setCurrentLabel,
                onSubmitted: controller.setCurrentLabel,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '指针速度',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Text('$speed', style: theme.textTheme.headlineSmall),
                ],
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
                  FilledButton.icon(
                    onPressed: controller.speeds.length < maxLevelCount
                        ? controller.addLevel
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('添加档位'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.speeds.length > minLevelCount
                        ? controller.removeCurrentLevel
                        : null,
                    icon: const Icon(Icons.remove),
                    label: const Text('删除当前档'),
                  ),
                  TextButton.icon(
                    onPressed: controller.captureSystemSpeed,
                    icon: const Icon(Icons.mouse_outlined),
                    label: const Text('读入当前系统速度'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HotkeysPage extends StatelessWidget {
  const _HotkeysPage({required this.controller});

  final DetentController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(String, String, bool)>[
      ('上一档', 'Ctrl+Alt+↑', controller.hotkeys.previous),
      ('下一档', 'Ctrl+Alt+↓', controller.hotkeys.next),
      for (var i = 0; i < directHotkeyCount; i++)
        ('跳到第 ${i + 1} 档', 'Ctrl+Alt+${i + 1}', controller.hotkeys.directAt(i)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          '全局快捷键',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          controller.hotkeyStatus(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final row in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              row.$3 ? Icons.check_circle : Icons.error_outline,
              color: row.$3
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            title: Text(row.$1),
            subtitle: Text(row.$2),
            trailing: Text(row.$3 ? '已注册' : '未注册'),
          ),
      ],
    );
  }
}

class _GeneralPage extends StatelessWidget {
  const _GeneralPage({required this.controller});

  final DetentController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      children: [
        ListTile(
          title: Text(
            '启动与窗口',
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
        SwitchListTile(
          title: const Text('窗口置顶'),
          subtitle: const Text('设置窗口保持在其他窗口前面'),
          value: controller.alwaysOnTop,
          onChanged: (value) => controller.setAlwaysOnTop(value),
        ),
        const Divider(),
        ListTile(
          title: Text(
            '数据',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          title: const Text('恢复默认档位'),
          subtitle: Text(
            '恢复为 ${defaultSpeeds.join('、')}，并关掉开机启动与置顶',
          ),
          trailing: FilledButton.tonal(
            onPressed: controller.resetDefaults,
            child: const Text('恢复'),
          ),
        ),
        ListTile(
          title: const Text('设置文件'),
          subtitle: Text(settingsFilePath()),
          trailing: IconButton(
            tooltip: '复制路径',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: settingsFilePath()));
            },
            icon: const Icon(Icons.copy_outlined),
          ),
        ),
      ],
    );
  }
}

class _AboutPage extends StatelessWidget {
  const _AboutPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 56,
              height: 56,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detent', style: theme.textTheme.headlineSmall),
                Text(
                  '1.0.0',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('多档系统指针速度'),
          subtitle: Text('托盘常驻，全局快捷键切档，适合需要快速改灵敏度的开发场景。'),
        ),
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('开源许可'),
          subtitle: Text('MIT'),
        ),
      ],
    );
  }
}
