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
        final theme = Theme.of(context);
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(index: controller.index, speed: speed),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < controller.speeds.length; i++)
                      _GearChip(
                        index: i,
                        speed: controller.speeds[i],
                        selected: i == controller.index,
                        onTap: () => controller.applyIndex(i),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '当前档的指针速度',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text('$speed', style: theme.textTheme.titleMedium),
                  ],
                ),
                Slider(
                  min: 1,
                  max: 20,
                  divisions: 19,
                  value: speed.toDouble(),
                  onChanged: (value) => controller.setCurrentSpeed(value.round()),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: controller.speeds.length < maxLevelCount
                            ? controller.addLevel
                            : null,
                        child: const Text('添加档位'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.speeds.length > minLevelCount
                            ? controller.removeCurrentLevel
                            : null,
                        child: const Text('删除当前档'),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('开机启动'),
                  value: controller.startWithWindows,
                  onChanged: controller.setStartup,
                ),
                const Spacer(),
                Text(
                  controller.hotkeyStatus(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.index, required this.speed});

  final int index;
  final int speed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/logo.png',
            width: 40,
            height: 40,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detent', style: theme.textTheme.titleLarge),
              Text(
                '第 ${index + 1} 档 · 速度 $speed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GearChip extends StatelessWidget {
  const _GearChip({
    required this.index,
    required this.speed,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final int speed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('第 ${index + 1} 档'),
          Text(
            '$speed',
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      selected: selected,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }
}
