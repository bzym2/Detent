import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const minPointerSpeed = 1;
const maxPointerSpeed = 20;

int clampPointerSpeed(int speed) {
  if (speed < minPointerSpeed) {
    return minPointerSpeed;
  }
  if (speed > maxPointerSpeed) {
    return maxPointerSpeed;
  }
  return speed;
}

int getPointerSpeed() {
  return using((arena) {
    final value = arena<Int32>();
    SystemParametersInfo(
      SPI_GETMOUSESPEED,
      0,
      value,
      const SYSTEM_PARAMETERS_INFO_UPDATE_FLAGS(0),
    );
    return value.value;
  });
}

void setPointerSpeed(int speed) {
  final clamped = clampPointerSpeed(speed);
  // SPI_SETMOUSESPEED takes the speed in pvParam itself, not a pointer to it.
  SystemParametersInfo(
    SPI_SETMOUSESPEED,
    0,
    Pointer.fromAddress(clamped),
    SPIF_UPDATEINIFILE | SPIF_SENDCHANGE,
  );
}
