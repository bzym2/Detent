import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const directHotkeyCount = 6;
const idPrevious = 1;
const idNext = 2;
const idDirectFirst = 3;
const _vkUp = 0x26;
const _vkDown = 0x28;
const _vkDigit1 = 0x31;

class HotkeyRegistration {
  const HotkeyRegistration({
    required this.previous,
    required this.next,
    required this.direct,
    required this.threadId,
  });

  final bool previous;
  final bool next;
  final List<bool> direct;
  final int threadId;

  bool directAt(int index) {
    return index >= 0 && index < direct.length && direct[index];
  }

  static const failed = HotkeyRegistration(
    previous: false,
    next: false,
    direct: <bool>[false, false, false, false, false, false],
    threadId: 0,
  );
}

void hotkeyIsolate(SendPort port) {
  final mods = MOD_CONTROL | MOD_ALT | MOD_NOREPEAT;
  final previous = RegisterHotKey(null, idPrevious, mods, _vkUp).value;
  final next = RegisterHotKey(null, idNext, mods, _vkDown).value;
  final direct = <bool>[];
  for (var i = 0; i < directHotkeyCount; i++) {
    direct.add(
      RegisterHotKey(null, idDirectFirst + i, mods, _vkDigit1 + i).value,
    );
  }
  port.send(<String, Object>{
    'threadId': GetCurrentThreadId(),
    'previous': previous,
    'next': next,
    'direct': direct,
  });

  final msg = calloc<MSG>();
  try {
    while (GetMessage(msg, null, 0, 0).value) {
      if (msg.ref.message == WM_HOTKEY) {
        final int hotkeyId = msg.ref.wParam;
        port.send(hotkeyId);
      }
      TranslateMessage(msg);
      DispatchMessage(msg);
    }
  } finally {
    UnregisterHotKey(null, idPrevious);
    UnregisterHotKey(null, idNext);
    for (var i = 0; i < directHotkeyCount; i++) {
      UnregisterHotKey(null, idDirectFirst + i);
    }
    calloc.free(msg);
  }
}

void stopHotkeyThread(int threadId) {
  if (threadId == 0) {
    return;
  }
  try {
    PostThreadMessage(threadId, WM_QUIT, const WPARAM(0), const LPARAM(0));
  } catch (_) {}
}

Future<HotkeyRegistration> listenForHotkeys(void Function(int id) onId) async {
  final port = ReceivePort();
  try {
    await Isolate.spawn(hotkeyIsolate, port.sendPort);
  } catch (_) {
    port.close();
    return HotkeyRegistration.failed;
  }

  final ready = Completer<HotkeyRegistration>();
  port.listen((message) {
    if (message is Map) {
      final directRaw = message['direct'];
      final direct = <bool>[];
      if (directRaw is List) {
        for (final item in directRaw) {
          direct.add(item == true);
        }
      }
      while (direct.length < directHotkeyCount) {
        direct.add(false);
      }
      if (!ready.isCompleted) {
        ready.complete(
          HotkeyRegistration(
            previous: message['previous'] == true,
            next: message['next'] == true,
            direct: direct,
            threadId: message['threadId'] is int ? message['threadId'] as int : 0,
          ),
        );
      }
      return;
    }
    if (message is int) {
      onId(message);
    }
  });
  return ready.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () => HotkeyRegistration.failed,
  );
}
