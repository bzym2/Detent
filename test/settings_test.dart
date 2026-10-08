import 'package:detent/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults are the six pointer speeds', () {
    final settings = createDefaultSettings();
    expect(settings.speeds, [4, 6, 8, 10, 14, 18]);
    expect(settings.index, 0);
    expect(settings.startWithWindows, isFalse);
  });

  test('unreadable json is rejected without a value', () {
    expect(tryParseSettings('{ this is not json'), isNull);
  });
}
