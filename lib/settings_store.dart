import 'dart:convert';
import 'dart:io';

const minLevelCount = 2;
const maxLevelCount = 9;
const defaultSpeeds = <int>[4, 6, 8, 10, 14, 18];

class AppSettings {
  AppSettings({
    required this.speeds,
    required this.index,
    required this.startWithWindows,
  });

  final List<int> speeds;
  final int index;
  final bool startWithWindows;
}

AppSettings createDefaultSettings() {
  return AppSettings(
    speeds: List<int>.of(defaultSpeeds),
    index: 0,
    startWithWindows: false,
  );
}

String settingsFilePath() {
  final local = Platform.environment['LOCALAPPDATA'] ??
      '${Platform.environment['USERPROFILE']}\\AppData\\Local';
  return '$local\\Detent\\settings.json';
}

AppSettings? tryParseSettings(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      return null;
    }
    final speedsRaw = decoded['speeds'];
    if (speedsRaw is! List ||
        speedsRaw.length < minLevelCount ||
        speedsRaw.length > maxLevelCount) {
      return null;
    }
    final speeds = <int>[];
    for (final item in speedsRaw) {
      if (item is! int || item < minPointerSpeedBound || item > maxPointerSpeedBound) {
        return null;
      }
      speeds.add(item);
    }
    final index = decoded['index'];
    if (index is! int || index < 0 || index >= speeds.length) {
      return null;
    }
    if (decoded.containsKey('startWithWindows') &&
        decoded['startWithWindows'] is! bool) {
      return null;
    }
    return AppSettings(
      speeds: speeds,
      index: index,
      startWithWindows: decoded['startWithWindows'] == true,
    );
  } catch (_) {
    return null;
  }
}

const minPointerSpeedBound = 1;
const maxPointerSpeedBound = 20;

AppSettings loadSettings() {
  final file = File(settingsFilePath());
  try {
    if (!file.existsSync()) {
      final created = createDefaultSettings();
      saveSettings(created);
      return created;
    }
    final parsed = tryParseSettings(file.readAsStringSync());
    if (parsed != null) {
      return parsed;
    }
  } catch (_) {
    // Unreadable settings stay on disk and the process keeps the defaults.
  }
  return createDefaultSettings();
}

void saveSettings(AppSettings settings) {
  try {
    final file = File(settingsFilePath());
    file.parent.createSync(recursive: true);
    final payload = const JsonEncoder.withIndent('  ').convert(<String, Object>{
      'speeds': settings.speeds,
      'index': settings.index,
      'startWithWindows': settings.startWithWindows,
    });
    final temp = File('${file.path}.tmp');
    temp.writeAsStringSync('$payload\n', flush: true);
    if (file.existsSync()) {
      file.deleteSync();
    }
    temp.renameSync(file.path);
  } catch (_) {
    // Keep the running levels if the disk write fails.
  }
}
