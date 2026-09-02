import 'package:flutter_test/flutter_test.dart';
import 'package:house_chores/data/rotation.dart';
import 'package:house_chores/models.dart';

void main() {
  test('downstairs rotates R1 → R2 → R3 from 19 Aug 2026', () {
    expect(downstairsRoom(DateTime(2026, 8, 19)), 1);
    expect(downstairsRoom(DateTime(2026, 8, 23)), 2);
    expect(downstairsRoom(DateTime(2026, 8, 26)), 3);
    expect(downstairsRoom(DateTime(2026, 8, 30)), 1);
    expect(downstairsRoom(DateTime(2026, 9, 2)), 2);
  });

  test('upstairs rotates R3 → R2 → R1 from 23 Aug 2026', () {
    expect(upstairsRoom(DateTime(2026, 8, 23)), 3);
    expect(upstairsRoom(DateTime(2026, 8, 30)), 2);
    expect(upstairsRoom(DateTime(2026, 9, 6)), 1);
    expect(upstairsRoom(DateTime(2026, 9, 13)), 3);
  });

  test('garbage windows and Sunday follows upstairs', () {
    expect(garbageRoom(DateTime(2026, 8, 17)), 3); // Mon
    expect(garbageRoom(DateTime(2026, 8, 18)), 3); // Tue
    expect(garbageRoom(DateTime(2026, 8, 19)), 1); // Wed
    expect(garbageRoom(DateTime(2026, 8, 20)), 1); // Thu
    expect(garbageRoom(DateTime(2026, 8, 21)), 2); // Fri
    expect(garbageRoom(DateTime(2026, 8, 22)), 2); // Sat
    expect(garbageRoom(DateTime(2026, 8, 23)), 3); // Sun = upstairs R3
    expect(garbageRoom(DateTime(2026, 8, 30)), 2);
  });

  test('Sunday downstairs and upstairs are never the same room', () {
    var d = DateTime(2026, 8, 23);
    for (var i = 0; i < 24; i++) {
      final down = downstairsRoom(d);
      final up = upstairsRoom(d);
      expect(down, isNotNull);
      expect(up, isNotNull);
      expect(down, isNot(up));
      d = addDays(d, 7);
    }
  });

  test('makeup skips the owing room’s own next turn', () {
    // R1 misses downstairs Wed 19 Aug; next downstairs is Sun 23 R2 → makeup there.
    expect(
      makeupDateFor(
        missedDate: DateTime(2026, 8, 19),
        jobType: JobType.downstairs,
        owingRoom: 1,
      ),
      DateTime(2026, 8, 23),
    );
  });

  test('a new house pins garbage to weekday rooms', () {
    final house = HouseProfile.blank(
      id: 'h2',
      name: 'Test',
      inviteCode: 'ZZZZ2222',
      rooms: const [
        HouseRoom(id: 1, name: 'A', colorValue: 0xFF2563EB),
        HouseRoom(id: 2, name: 'B', colorValue: 0xFF16A34A),
      ],
      people: const [Person(id: 'a', name: 'Ada', roomId: 1)],
      start: DateTime(2026, 9, 1),
    );
    expect(garbageRoom(DateTime(2026, 9, 1), house), 1); // Tue
    expect(garbageRoom(DateTime(2026, 9, 3), house), 2); // Thu
    expect(house.rule(JobType.garbage).sundayFollowsUpstairs, isTrue);
  });

  test('a new house rotates from its own epoch and rooms', () {
    final start = DateTime(2026, 9, 2); // Wednesday
    final house = HouseProfile.blank(
      id: 'h1',
      name: 'Test',
      inviteCode: 'ABCD2345',
      rooms: const [
        HouseRoom(id: 1, name: 'A', colorValue: 0xFF2563EB),
        HouseRoom(id: 2, name: 'B', colorValue: 0xFF16A34A),
      ],
      people: const [Person(id: 'a', name: 'Ada', roomId: 1)],
      start: start,
    );
    expect(downstairsRoom(start, house), 1);
    expect(downstairsRoom(DateTime(2026, 9, 6), house), 2); // Sunday
    expect(downstairsRoom(DateTime(2026, 9, 9), house), 1);
    expect(upstairsRoom(DateTime(2026, 9, 6), house), 2);
    expect(jobsOn(DateTime(2026, 9, 6), house).map((j) => j.jobType).toList(), [
      JobType.downstairs,
      JobType.upstairs,
    ]);
  });
}
