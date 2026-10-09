import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'hotkey_service.dart';
import 'pointer_speed.dart';
import 'settings_store.dart';
import 'startup_registration.dart';

class DetentController extends ChangeNotifier with WindowListener {
  DetentController();

  late List<int> speeds;
  late List<String> labels;
  late int index;
  late bool startWithWindows;
  late bool alwaysOnTop;
  HotkeyRegistration hotkeys = HotkeyRegistration.failed;
  bool exiting = false;

  TrayIcon? _tray;
  Image? _icon;
  final List<Object> _kept = [];

  Future<void> boot() async {
    final loaded = loadSettings();
    speeds = List<int>.of(loaded.speeds);
    labels = List<String>.of(loaded.labels);
    index = loaded.index;
    startWithWindows = loaded.startWithWindows;
    alwaysOnTop = loaded.alwaysOnTop;
    setPointerSpeed(speeds[index]);
    setStartupRegistration(startWithWindows);
    await windowManager.setAlwaysOnTop(alwaysOnTop);
    hotkeys = await listenForHotkeys(_onHotkey);
    _installTray();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  void _installTray() {
    try {
      final tray = TrayIcon.create();
      if (tray == null) {
        return;
      }
      _tray = tray;
      _icon = ImageAsset.fromAsset('assets/logo.png');
      if (_icon != null) {
        tray.icon = _icon;
      }
      tray.setTooltip('Detent');
      final menu = Menu.create();
      if (menu != null) {
        _kept.add(menu);
        final openItem =
            MenuItem.createWithLabelAndType('打开', MenuItemType.normal);
        final exitItem =
            MenuItem.createWithLabelAndType('退出', MenuItemType.normal);
        if (openItem != null) {
          _kept.add(openItem);
          openItem.addListener((event) {
            if (event is MenuItemClickedEvent) {
              openWindow();
            }
          });
          menu.addItem(openItem);
        }
        if (exitItem != null) {
          _kept.add(exitItem);
          exitItem.addListener((event) {
            if (event is MenuItemClickedEvent) {
              exitApp();
            }
          });
          menu.addItem(exitItem);
        }
        tray.setContextMenu(menu);
      }
      tray.setContextMenuTrigger(ContextMenuTrigger.rightClicked);
      tray.addListener((event) {
        if (event is TrayIconClickedEvent) {
          openWindow();
        }
      });
      tray.setVisible(true);
    } catch (_) {
      // Hotkeys still work when the tray icon cannot be created.
    }
  }

  void _onHotkey(int id) {
    if (id == idPrevious) {
      step(-1);
    } else if (id == idNext) {
      step(1);
    } else if (id >= idDirectFirst && id < idDirectFirst + directHotkeyCount) {
      jumpTo(id - idDirectFirst);
    }
  }

  void step(int delta) {
    applyIndex(index + delta);
  }

  void jumpTo(int target) {
    if (target < 0 || target >= speeds.length) {
      return;
    }
    applyIndex(target);
  }

  void applyIndex(int next) {
    final clamped = next.clamp(0, speeds.length - 1);
    if (clamped == index) {
      return;
    }
    index = clamped;
    setPointerSpeed(speeds[index]);
    _save();
    notifyListeners();
  }

  void setCurrentSpeed(int speed) {
    final clamped = clampPointerSpeed(speed);
    if (clamped == speeds[index]) {
      return;
    }
    speeds[index] = clamped;
    setPointerSpeed(clamped);
    _save();
    notifyListeners();
  }

  void setCurrentLabel(String label) {
    final trimmed = label.trim();
    final next = trimmed.isEmpty ? '未命名' : trimmed;
    if (next == labels[index]) {
      return;
    }
    labels[index] = next;
    _save();
    notifyListeners();
  }

  void addLevel() {
    if (speeds.length >= maxLevelCount) {
      return;
    }
    speeds.add(10);
    labels.add('第 ${speeds.length} 档');
    _save();
    notifyListeners();
  }

  void removeCurrentLevel() {
    if (speeds.length <= minLevelCount) {
      return;
    }
    speeds.removeAt(index);
    labels.removeAt(index);
    if (index >= speeds.length) {
      index = speeds.length - 1;
    }
    setPointerSpeed(speeds[index]);
    _save();
    notifyListeners();
  }

  void setStartup(bool enabled) {
    if (enabled == startWithWindows) {
      return;
    }
    startWithWindows = enabled;
    setStartupRegistration(enabled);
    _save();
    notifyListeners();
  }

  Future<void> setAlwaysOnTop(bool enabled) async {
    if (enabled == alwaysOnTop) {
      return;
    }
    alwaysOnTop = enabled;
    await windowManager.setAlwaysOnTop(enabled);
    _save();
    notifyListeners();
  }

  void captureSystemSpeed() {
    setCurrentSpeed(getPointerSpeed());
  }

  void resetDefaults() {
    final defaults = createDefaultSettings();
    speeds = List<int>.of(defaults.speeds);
    labels = List<String>.of(defaults.labels);
    index = defaults.index;
    startWithWindows = defaults.startWithWindows;
    alwaysOnTop = defaults.alwaysOnTop;
    setPointerSpeed(speeds[index]);
    setStartupRegistration(startWithWindows);
    windowManager.setAlwaysOnTop(alwaysOnTop);
    _save();
    notifyListeners();
  }

  String levelTitle(int i) {
    if (i < 0 || i >= labels.length) {
      return '第 ${i + 1} 档';
    }
    return labels[i];
  }

  String hotkeyStatus() {
    final failed = <String>[];
    if (!hotkeys.previous) {
      failed.add('Ctrl+Alt+↑');
    }
    if (!hotkeys.next) {
      failed.add('Ctrl+Alt+↓');
    }
    for (var i = 0; i < directHotkeyCount; i++) {
      if (!hotkeys.directAt(i)) {
        failed.add('Ctrl+Alt+${i + 1}');
      }
    }
    if (failed.isEmpty) {
      return 'Ctrl+Alt+↑ 上一档，Ctrl+Alt+↓ 下一档，Ctrl+Alt+1 到 6 跳到对应档';
    }
    return '快捷键注册失败，可能被别的程序占用了：${failed.join('、')}';
  }

  Future<void> openWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> exitApp() async {
    if (exiting) {
      return;
    }
    exiting = true;
    try {
      _tray?.dispose();
    } catch (_) {}
    _kept.clear();
    stopHotkeyThread(hotkeys.threadId);
    try {
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
    } catch (_) {}
    exit(0);
  }

  void _save() {
    saveSettings(
      AppSettings(
        speeds: List<int>.of(speeds),
        index: index,
        startWithWindows: startWithWindows,
        labels: List<String>.of(labels),
        alwaysOnTop: alwaysOnTop,
      ),
    );
  }

  @override
  void onWindowClose() {
    if (exiting) {
      return;
    }
    windowManager.hide();
  }
}
