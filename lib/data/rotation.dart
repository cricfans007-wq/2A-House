import '../models.dart';

final downstairsEpoch = DateTime(2026, 8, 19);
final upstairsEpoch = DateTime(2026, 8, 23);

const downstairsCycle = [1, 2, 3];
const upstairsCycle = [3, 2, 1];

const roomNames = {1: 'Room 1', 2: 'Room 2', 3: 'Room 3'};

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

bool isWedOrSun(DateTime d) =>
    d.weekday == DateTime.wednesday || d.weekday == DateTime.sunday;

int countMatching(DateTime start, DateTime end, bool Function(DateTime) pred) {
  var n = 0;
  var d = dateOnly(start);
  final last = dateOnly(end);
  while (!d.isAfter(last)) {
    if (pred(d)) n++;
    d = addDays(d, 1);
  }
  return n;
}

int? downstairsRoom(DateTime date) {
  final d = dateOnly(date);
  if (d.isBefore(dateOnly(downstairsEpoch))) return null;
  if (!isWedOrSun(d)) return null;
  final n = countMatching(downstairsEpoch, d, isWedOrSun);
  return downstairsCycle[(n - 1) % downstairsCycle.length];
}

int? upstairsRoom(DateTime date) {
  final d = dateOnly(date);
  if (d.weekday != DateTime.sunday) return null;
  if (d.isBefore(dateOnly(upstairsEpoch))) return null;
  final n = countMatching(
    upstairsEpoch,
    d,
    (x) => x.weekday == DateTime.sunday,
  );
  return upstairsCycle[(n - 1) % upstairsCycle.length];
}

int? garbageRoom(DateTime date) {
  final d = dateOnly(date);
  switch (d.weekday) {
    case DateTime.monday:
    case DateTime.tuesday:
      return 3;
    case DateTime.wednesday:
    case DateTime.thursday:
      return 1;
    case DateTime.friday:
    case DateTime.saturday:
      return 2;
    case DateTime.sunday:
      return upstairsRoom(d);
    default:
      return null;
  }
}

int? scheduledRoom(DateTime date, JobType job) => switch (job) {
  JobType.downstairs => downstairsRoom(date),
  JobType.upstairs => upstairsRoom(date),
  JobType.garbage => garbageRoom(date),
};

bool hasJob(DateTime date, JobType job) => scheduledRoom(date, job) != null;

String occurrenceId(
  DateTime date,
  JobType job, {
  bool makeup = false,
  int? room,
}) {
  final day = dateOnly(date).toIso8601String().split('T').first;
  if (makeup) return '${day}_${job.id}_makeup_r$room';
  return '${day}_${job.id}';
}

class PlannedJob {
  const PlannedJob({
    required this.jobType,
    required this.roomId,
    this.includesSundayGarbage = false,
  });

  final JobType jobType;
  final int roomId;
  final bool includesSundayGarbage;
}

/// Sunday garbage is folded into the upstairs card, not listed twice.
List<PlannedJob> jobsOn(DateTime date) {
  final d = dateOnly(date);
  final jobs = <PlannedJob>[];
  final down = downstairsRoom(d);
  if (down != null) {
    jobs.add(PlannedJob(jobType: JobType.downstairs, roomId: down));
  }
  final up = upstairsRoom(d);
  if (up != null) {
    jobs.add(
      PlannedJob(
        jobType: JobType.upstairs,
        roomId: up,
        includesSundayGarbage: true,
      ),
    );
  }
  if (d.weekday != DateTime.sunday) {
    final g = garbageRoom(d);
    if (g != null) {
      jobs.add(PlannedJob(jobType: JobType.garbage, roomId: g));
    }
  }
  return jobs;
}

DateTime startOfWeek(DateTime date) {
  final d = dateOnly(date);
  return addDays(d, 1 - d.weekday);
}

/// Next extra day for a missed job. Skips the owing room's own next turn
/// so "2×" is actually extra work, not collapsed into their normal slot.
DateTime? makeupDateFor({
  required DateTime missedDate,
  required JobType jobType,
  required int owingRoom,
  int searchDays = 120,
}) {
  var skippedOwnTurn = false;
  var d = addDays(dateOnly(missedDate), 1);
  final limit = addDays(d, searchDays);
  while (!d.isAfter(limit)) {
    if (hasJob(d, jobType)) {
      final scheduled = scheduledRoom(d, jobType);
      if (scheduled == owingRoom && !skippedOwnTurn) {
        skippedOwnTurn = true;
      } else {
        return d;
      }
    }
    d = addDays(d, 1);
  }
  return null;
}

List<DateTime> daysInRange(DateTime start, DateTime end) {
  final out = <DateTime>[];
  var d = dateOnly(start);
  final last = dateOnly(end);
  while (!d.isAfter(last)) {
    out.add(d);
    d = addDays(d, 1);
  }
  return out;
}
