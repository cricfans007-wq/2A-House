import '../models.dart';

HouseProfile _house(HouseProfile? house) => house ?? HouseProfile.twoA();

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

int? scheduledRoom(DateTime date, JobType job, [HouseProfile? profile]) {
  final house = _house(profile);
  final rule = house.rule(job);
  if (!rule.enabled) return null;
  final d = dateOnly(date);

  if (rule.sundayFollowsUpstairs && d.weekday == DateTime.sunday) {
    if (job == JobType.garbage) {
      return scheduledRoom(d, JobType.upstairs, house);
    }
  }

  if (rule.weekdayRooms.isNotEmpty) {
    return rule.weekdayRooms[d.weekday];
  }

  if (rule.epoch == null || rule.cycle.isEmpty) return null;
  final epoch = dateOnly(rule.epoch!);
  if (d.isBefore(epoch)) return null;
  if (!rule.weekdays.contains(d.weekday)) return null;
  final n = countMatching(epoch, d, (x) => rule.weekdays.contains(x.weekday));
  if (n <= 0) return null;
  return rule.cycle[(n - 1) % rule.cycle.length];
}

int? downstairsRoom(DateTime date, [HouseProfile? house]) =>
    scheduledRoom(date, JobType.downstairs, house);

int? upstairsRoom(DateTime date, [HouseProfile? house]) =>
    scheduledRoom(date, JobType.upstairs, house);

int? garbageRoom(DateTime date, [HouseProfile? house]) =>
    scheduledRoom(date, JobType.garbage, house);

bool hasJob(DateTime date, JobType job, [HouseProfile? house]) =>
    scheduledRoom(date, job, house) != null;

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

/// Sunday garbage is folded into the upstairs card when it follows upstairs.
List<PlannedJob> jobsOn(DateTime date, [HouseProfile? profile]) {
  final house = _house(profile);
  final d = dateOnly(date);
  final jobs = <PlannedJob>[];
  final down = downstairsRoom(d, house);
  if (down != null) {
    jobs.add(PlannedJob(jobType: JobType.downstairs, roomId: down));
  }
  final up = upstairsRoom(d, house);
  final garbageFollowsUp =
      house.rule(JobType.garbage).sundayFollowsUpstairs &&
      d.weekday == DateTime.sunday &&
      up != null;
  if (up != null) {
    jobs.add(
      PlannedJob(
        jobType: JobType.upstairs,
        roomId: up,
        includesSundayGarbage: garbageFollowsUp,
      ),
    );
  }
  if (!garbageFollowsUp) {
    final g = garbageRoom(d, house);
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

DateTime? makeupDateFor({
  required DateTime missedDate,
  required JobType jobType,
  required int owingRoom,
  HouseProfile? house,
  int searchDays = 120,
}) {
  var skippedOwnTurn = false;
  var d = addDays(dateOnly(missedDate), 1);
  final limit = addDays(d, searchDays);
  while (!d.isAfter(limit)) {
    if (hasJob(d, jobType, house)) {
      final scheduled = scheduledRoom(d, jobType, house);
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
