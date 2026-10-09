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
        visualDensity: VisualDensity.comfortable,
        listTileTheme: const ListTileThemeData(
          dense: false,
          visualDensity: VisualDensity.comfortable,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
        final title = controller.levelTitle(controller.index);
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: true,
                minExtendedWidth: 168,
                selectedIndex: _section,
                onDestinationSelected: (value) {
                  setState(() => _section = value);
                },
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 24),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 48,
                        height: 48,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Detent',
                          style: theme.textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopStatus(
                      title: title,
                      speed: speed,
                      section: _section,
                    ),
                    const Divider(height: 1),
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
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopStatus extends StatelessWidget {
  const _TopStatus({
    required this.title,
    required this.speed,
    required this.section,
  });

  final String title;
  final int speed;
  final int section;

  static const _sectionNames = ['档位', '快捷键', '常规', '关于'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sectionNames[section],
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            '正在使用 $title · 指针速度 $speed',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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
          width: 300,
          child: Material(
            color: theme.colorScheme.surfaceContainerLowest,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              itemCount: controller.speeds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final selected = i == controller.index;
                return ListTile(
                  selected: selected,
                  selectedTileColor: theme.colorScheme.secondaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  title: Text(
                    controller.levelTitle(i),
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text('速度 ${controller.speeds[i]}'),
                  onTap: () => controller.applyIndex(i),
                );
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
            children: [
              Text(
                '先选左边的档，再在这里改名称和速度。',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: '档位名称',
                  helperText: '改完会立刻保存',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onChanged: controller.setCurrentLabel,
                onSubmitted: controller.setCurrentLabel,
              ),
              const SizedBox(height: 32),
              Text('指针速度', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: speed > 1
                        ? () => controller.setCurrentSpeed(speed - 1)
                        : null,
                    icon: const Icon(Icons.remove),
                    tooltip: '减 1',
                  ),
                  Expanded(
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
                  IconButton.filledTonal(
                    onPressed: speed < 20
                        ? () => controller.setCurrentSpeed(speed + 1)
                        : null,
                    icon: const Icon(Icons.add),
                    tooltip: '加 1',
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$speed',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 12,
                runSpacing: 12,
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
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('删除当前档'),
                  ),
                  TextButton.icon(
                    onPressed: controller.captureSystemSpeed,
                    icon: const Icon(Icons.mouse_outlined),
                    label: const Text('读入系统速度'),
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
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      children: [
        Text(
          controller.hotkeyStatus(),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: theme.colorScheme.surfaceContainerLowest,
              leading: Icon(
                row.$3 ? Icons.check_circle : Icons.error_outline,
                color: row.$3
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              title: Text(row.$1, style: theme.textTheme.titleMedium),
              subtitle: Text(row.$2),
              trailing: Text(row.$3 ? '已注册' : '未注册'),
            ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        SwitchListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('开机启动'),
          subtitle: const Text('登录 Windows 后自动打开 Detent'),
          value: controller.startWithWindows,
          onChanged: controller.setStartup,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('窗口置顶'),
          subtitle: const Text('设置窗口保持在其他窗口前面'),
          value: controller.alwaysOnTop,
          onChanged: (value) => controller.setAlwaysOnTop(value),
        ),
        const SizedBox(height: 24),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('恢复默认档位'),
          subtitle: Text('恢复为 ${defaultSpeeds.join('、')}，并关掉开机启动与置顶'),
          trailing: FilledButton.tonal(
            onPressed: controller.resetDefaults,
            child: const Text('恢复'),
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 72,
              height: 72,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detent', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  '1.0.0 · MIT',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          '多档系统指针速度，托盘常驻，全局快捷键切档。',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
