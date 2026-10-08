import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const _runKey = r'Software\Microsoft\Windows\CurrentVersion\Run';
const _valueName = 'Detent';

void setStartupRegistration(bool enabled) {
  try {
    using((arena) {
      final phk = arena<IntPtr>();
      final created = RegCreateKeyEx(
        HKEY_CURRENT_USER,
        arena.pcwstr(_runKey),
        null,
        REG_OPTION_NON_VOLATILE,
        KEY_SET_VALUE,
        null,
        phk.cast(),
        null,
      );
      if (created != ERROR_SUCCESS) {
        return;
      }
      final hkey = HKEY(Pointer.fromAddress(phk.value));
      try {
        if (!enabled) {
          RegDeleteValue(hkey, arena.pcwstr(_valueName));
          return;
        }
        final path = Platform.resolvedExecutable.trim();
        if (path.isEmpty) {
          return;
        }
        final value = arena.pcwstr(path);
        RegSetValueEx(
          hkey,
          arena.pcwstr(_valueName),
          REG_SZ,
          value.cast(),
          value.byteLength + 2,
        );
      } finally {
        RegCloseKey(hkey);
      }
    });
  } catch (_) {
    // The switch still shows the choice. The next launch tries again.
  }
}
