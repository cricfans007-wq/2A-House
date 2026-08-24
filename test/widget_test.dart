import 'package:flutter_test/flutter_test.dart';
import 'package:house_chores/data/rotation.dart';

void main() {
  test('date helpers keep calendar days stable', () {
    expect(dateOnly(DateTime(2026, 8, 19, 23, 59)), DateTime(2026, 8, 19));
    expect(addDays(DateTime(2026, 8, 31), 1), DateTime(2026, 9, 1));
    expect(startOfWeek(DateTime(2026, 8, 19)), DateTime(2026, 8, 17));
  });
}
