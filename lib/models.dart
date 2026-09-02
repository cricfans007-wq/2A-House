import 'package:flutter/material.dart';

enum JobType { downstairs, upstairs, garbage }

extension JobTypeX on JobType {
  String get id => name;

  String get title => switch (this) {
    JobType.downstairs => 'Downstairs',
    JobType.upstairs => 'Upstairs',
    JobType.garbage => 'Garbage',
  };

  String get blurb => switch (this) {
    JobType.downstairs => 'Kitchen, hall, shoe rack, toilet',
    JobType.upstairs => 'Bathroom, lobby, stairs',
    JobType.garbage => 'Take the bins out',
  };

  List<String> get checklist => switch (this) {
    JobType.downstairs => [
      'Kitchen — stove, sink, counters, floor',
      'Hall',
      'Shoe rack',
      'Toilet',
    ],
    JobType.upstairs => ['Bathroom', 'Lobby', 'Stairs', 'Dump garbage'],
    JobType.garbage => ['Take out the garbage'],
  };

  IconData get icon => switch (this) {
    JobType.downstairs => Icons.countertops_outlined,
    JobType.upstairs => Icons.stairs_outlined,
    JobType.garbage => Icons.delete_outline,
  };

  static JobType fromId(String id) =>
      JobType.values.firstWhere((j) => j.name == id);
}

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.roomId,
    this.phone = '',
  });

  final String id;
  final String name;
  final int roomId;
  final String phone;

  Person copyWith({String? name, int? roomId, String? phone}) => Person(
    id: id,
    name: name ?? this.name,
    roomId: roomId ?? this.roomId,
    phone: phone ?? this.phone,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'roomId': roomId,
    'phone': phone,
  };

  factory Person.fromMap(Map map) => Person(
    id: map['id'] as String,
    name: map['name'] as String,
    roomId: map['roomId'] as int,
    phone: (map['phone'] as String?) ?? '',
  );
}

class Occurrence {
  const Occurrence({
    required this.id,
    required this.date,
    required this.jobType,
    required this.assignedRoom,
    this.completed = false,
    this.completedAt,
    this.completedById,
    this.notifiedOnTime = false,
    this.notifiedAt,
    this.notifiedById,
    this.notes = '',
    this.isMakeup = false,
    this.missedDate,
  });

  final String id;
  final DateTime date;
  final JobType jobType;
  final int assignedRoom;
  final bool completed;
  final DateTime? completedAt;
  final String? completedById;
  final bool notifiedOnTime;
  final DateTime? notifiedAt;
  final String? notifiedById;
  final String notes;
  final bool isMakeup;
  final DateTime? missedDate;

  Occurrence copyWith({
    int? assignedRoom,
    bool? completed,
    DateTime? completedAt,
    String? completedById,
    bool? notifiedOnTime,
    DateTime? notifiedAt,
    String? notifiedById,
    String? notes,
    bool clearNotified = false,
  }) => Occurrence(
    id: id,
    date: date,
    jobType: jobType,
    assignedRoom: assignedRoom ?? this.assignedRoom,
    completed: completed ?? this.completed,
    completedAt: completedAt ?? this.completedAt,
    completedById: completedById ?? this.completedById,
    notifiedOnTime: notifiedOnTime ?? this.notifiedOnTime,
    notifiedAt: clearNotified ? null : (notifiedAt ?? this.notifiedAt),
    notifiedById: clearNotified ? null : (notifiedById ?? this.notifiedById),
    notes: notes ?? this.notes,
    isMakeup: isMakeup,
    missedDate: missedDate,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'jobType': jobType.id,
    'assignedRoom': assignedRoom,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'completedById': completedById,
    'notifiedOnTime': notifiedOnTime,
    'notifiedAt': notifiedAt?.toIso8601String(),
    'notifiedById': notifiedById,
    'notes': notes,
    'isMakeup': isMakeup,
    'missedDate': missedDate?.toIso8601String(),
  };

  factory Occurrence.fromMap(Map map) => Occurrence(
    id: map['id'] as String,
    date: DateTime.parse(map['date'] as String),
    jobType: JobTypeX.fromId(map['jobType'] as String),
    assignedRoom: (map['assignedRoom'] as num).toInt(),
    completed: (map['completed'] as bool?) ?? false,
    completedAt: _parseTime(map['completedAt']),
    completedById: map['completedById'] as String?,
    notifiedOnTime: (map['notifiedOnTime'] as bool?) ?? false,
    notifiedAt: _parseTime(map['notifiedAt']),
    notifiedById: map['notifiedById'] as String?,
    notes: (map['notes'] as String?) ?? '',
    isMakeup: (map['isMakeup'] as bool?) ?? false,
    missedDate: _parseTime(map['missedDate']),
  );
}

class PenaltyDebt {
  const PenaltyDebt({
    required this.id,
    required this.roomId,
    required this.jobType,
    required this.missedDate,
    this.resolved = false,
    this.makeupDate,
  });

  final String id;
  final int roomId;
  final JobType jobType;
  final DateTime missedDate;
  final bool resolved;
  final DateTime? makeupDate;

  PenaltyDebt copyWith({bool? resolved, DateTime? makeupDate}) => PenaltyDebt(
    id: id,
    roomId: roomId,
    jobType: jobType,
    missedDate: missedDate,
    resolved: resolved ?? this.resolved,
    makeupDate: makeupDate ?? this.makeupDate,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'roomId': roomId,
    'jobType': jobType.id,
    'missedDate': missedDate.toIso8601String(),
    'resolved': resolved,
    'makeupDate': makeupDate?.toIso8601String(),
  };

  factory PenaltyDebt.fromMap(Map map) => PenaltyDebt(
    id: map['id'] as String,
    roomId: map['roomId'] as int,
    jobType: JobTypeX.fromId(map['jobType'] as String),
    missedDate: DateTime.parse(map['missedDate'] as String),
    resolved: (map['resolved'] as bool?) ?? false,
    makeupDate: _parseTime(map['makeupDate']),
  );
}

class AppSettings {
  const AppSettings({
    this.myPersonId,
    this.notifyHour = 20,
    this.houseId,
    this.inviteCode,
  });

  final String? myPersonId;
  final int notifyHour;
  final String? houseId;
  final String? inviteCode;

  bool get hasHouse => houseId != null && houseId!.isNotEmpty;

  AppSettings copyWith({
    String? myPersonId,
    int? notifyHour,
    String? houseId,
    String? inviteCode,
    bool clearPerson = false,
    bool clearHouse = false,
  }) => AppSettings(
    myPersonId: clearPerson ? null : (myPersonId ?? this.myPersonId),
    notifyHour: notifyHour ?? this.notifyHour,
    houseId: clearHouse ? null : (houseId ?? this.houseId),
    inviteCode: clearHouse ? null : (inviteCode ?? this.inviteCode),
  );

  Map<String, dynamic> toMap() => {
    'myPersonId': myPersonId,
    'notifyHour': notifyHour,
    'houseId': houseId,
    'inviteCode': inviteCode,
  };

  factory AppSettings.fromMap(Map map) => AppSettings(
    myPersonId: map['myPersonId'] as String?,
    notifyHour: (map['notifyHour'] as int?) ?? 20,
    houseId: map['houseId'] as String?,
    inviteCode: map['inviteCode'] as String?,
  );
}

const roomPalette = [
  0xFF2563EB,
  0xFF16A34A,
  0xFFEA580C,
  0xFF7C3AED,
  0xFFDB2777,
  0xFF0F766E,
  0xFFCA8A04,
  0xFF0E7490,
];

class HouseRoom {
  const HouseRoom({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  final int id;
  final String name;
  final int colorValue;

  HouseRoom copyWith({String? name, int? colorValue}) => HouseRoom(
    id: id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
  };

  factory HouseRoom.fromMap(Map map) => HouseRoom(
    id: (map['id'] as num).toInt(),
    name: (map['name'] as String?) ?? 'Room ${(map['id'] as num).toInt()}',
    colorValue:
        (map['colorValue'] as num?)?.toInt() ??
        roomPalette[((map['id'] as num).toInt() - 1) % roomPalette.length],
  );
}

class JobRule {
  const JobRule({
    required this.type,
    required this.title,
    required this.blurb,
    required this.checklist,
    required this.weekdays,
    required this.cycle,
    this.epoch,
    this.enabled = true,
    this.sundayFollowsUpstairs = false,
    this.weekdayRooms = const {},
  });

  final JobType type;
  final String title;
  final String blurb;
  final List<String> checklist;
  final List<int> weekdays;
  final List<int> cycle;
  final DateTime? epoch;
  final bool enabled;
  final bool sundayFollowsUpstairs;
  final Map<int, int> weekdayRooms;

  JobRule copyWith({
    String? title,
    String? blurb,
    List<String>? checklist,
    List<int>? weekdays,
    List<int>? cycle,
    DateTime? epoch,
    bool? enabled,
    bool? sundayFollowsUpstairs,
    Map<int, int>? weekdayRooms,
    bool clearEpoch = false,
  }) => JobRule(
    type: type,
    title: title ?? this.title,
    blurb: blurb ?? this.blurb,
    checklist: checklist ?? this.checklist,
    weekdays: weekdays ?? this.weekdays,
    cycle: cycle ?? this.cycle,
    epoch: clearEpoch ? null : (epoch ?? this.epoch),
    enabled: enabled ?? this.enabled,
    sundayFollowsUpstairs: sundayFollowsUpstairs ?? this.sundayFollowsUpstairs,
    weekdayRooms: weekdayRooms ?? this.weekdayRooms,
  );

  Map<String, dynamic> toMap() => {
    'type': type.id,
    'title': title,
    'blurb': blurb,
    'checklist': checklist,
    'weekdays': weekdays,
    'cycle': cycle,
    'epoch': epoch?.toIso8601String(),
    'enabled': enabled,
    'sundayFollowsUpstairs': sundayFollowsUpstairs,
    'weekdayRooms': {for (final e in weekdayRooms.entries) '${e.key}': e.value},
  };

  factory JobRule.fromMap(Map map, JobType fallback) {
    final type = JobTypeX.fromId((map['type'] as String?) ?? fallback.id);
    final rooms = <int, int>{};
    final rawRooms = map['weekdayRooms'];
    if (rawRooms is Map) {
      for (final e in rawRooms.entries) {
        rooms[int.parse(e.key.toString())] = (e.value as num).toInt();
      }
    }
    return JobRule(
      type: type,
      title: (map['title'] as String?) ?? fallback.title,
      blurb: (map['blurb'] as String?) ?? fallback.blurb,
      checklist: ((map['checklist'] as List?) ?? fallback.checklist)
          .map((e) => e.toString())
          .toList(),
      weekdays: ((map['weekdays'] as List?) ?? const <int>[])
          .map((e) => (e as num).toInt())
          .toList(),
      cycle: ((map['cycle'] as List?) ?? const <int>[])
          .map((e) => (e as num).toInt())
          .toList(),
      epoch: _parseTime(map['epoch']),
      enabled: (map['enabled'] as bool?) ?? true,
      sundayFollowsUpstairs: (map['sundayFollowsUpstairs'] as bool?) ?? false,
      weekdayRooms: rooms,
    );
  }
}

class HouseProfile {
  const HouseProfile({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.rooms,
    required this.people,
    required this.rules,
    this.memberUids = const [],
  });

  final String id;
  final String name;
  final String inviteCode;
  final List<HouseRoom> rooms;
  final List<Person> people;
  final Map<JobType, JobRule> rules;
  final List<String> memberUids;

  JobRule rule(JobType type) => rules[type] ?? JobRule.fromMap(const {}, type);

  HouseRoom? roomById(int id) {
    for (final r in rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  String roomLabel(int id) => roomById(id)?.name ?? 'Room $id';

  String rulesSummary() {
    final down = rule(JobType.downstairs);
    final up = rule(JobType.upstairs);
    return '${down.title} ${down.cycle.map((r) => 'R$r').join('→')} · ${up.title} ${up.cycle.map((r) => 'R$r').join('→')}';
  }

  HouseProfile copyWith({
    String? name,
    String? inviteCode,
    List<HouseRoom>? rooms,
    List<Person>? people,
    Map<JobType, JobRule>? rules,
    List<String>? memberUids,
  }) => HouseProfile(
    id: id,
    name: name ?? this.name,
    inviteCode: inviteCode ?? this.inviteCode,
    rooms: rooms ?? this.rooms,
    people: people ?? this.people,
    rules: rules ?? this.rules,
    memberUids: memberUids ?? this.memberUids,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'inviteCode': inviteCode,
    'rooms': rooms.map((r) => r.toMap()).toList(),
    'people': people.map((p) => p.toMap()).toList(),
    'rules': {for (final e in rules.entries) e.key.id: e.value.toMap()},
    'memberUids': memberUids,
  };

  factory HouseProfile.fromMap(Map map) {
    final rulesRaw = map['rules'];
    final rules = <JobType, JobRule>{};
    if (rulesRaw is Map) {
      for (final type in JobType.values) {
        final raw = rulesRaw[type.id];
        if (raw is Map) {
          rules[type] = JobRule.fromMap(Map<String, dynamic>.from(raw), type);
        }
      }
    }
    for (final type in JobType.values) {
      rules.putIfAbsent(type, () => defaultRule(type, const [1, 2]));
    }
    return HouseProfile(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? 'House',
      inviteCode: (map['inviteCode'] as String?) ?? '',
      rooms: ((map['rooms'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => HouseRoom.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      people: ((map['people'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => Person.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      rules: rules,
      memberUids: ((map['memberUids'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static Map<int, int> pairedWeekdayRooms(List<int> roomIds) {
    final ids = roomIds.isEmpty ? const [1] : roomIds;
    final chunk = (6 / ids.length).ceil().clamp(1, 6);
    return {
      for (var w = DateTime.monday; w <= DateTime.saturday; w++)
        w: ids[((w - 1) ~/ chunk) % ids.length],
    };
  }

  static JobRule defaultRule(
    JobType type,
    List<int> roomIds, {
    DateTime? start,
  }) {
    final epoch = DateTime(
      (start ?? DateTime.now()).year,
      (start ?? DateTime.now()).month,
      (start ?? DateTime.now()).day,
    );
    final rooms = roomIds.isEmpty ? [1] : roomIds;
    return switch (type) {
      JobType.downstairs => JobRule(
        type: type,
        title: type.title,
        blurb: type.blurb,
        checklist: type.checklist,
        weekdays: const [DateTime.wednesday, DateTime.sunday],
        cycle: rooms,
        epoch: epoch,
      ),
      JobType.upstairs => JobRule(
        type: type,
        title: type.title,
        blurb: type.blurb,
        checklist: type.checklist,
        weekdays: const [DateTime.sunday],
        cycle: rooms.reversed.toList(),
        epoch: epoch,
      ),
      JobType.garbage => JobRule(
        type: type,
        title: type.title,
        blurb: type.blurb,
        checklist: type.checklist,
        weekdays: const [
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
          DateTime.saturday,
          DateTime.sunday,
        ],
        cycle: rooms,
        epoch: epoch,
        sundayFollowsUpstairs: true,
        weekdayRooms: pairedWeekdayRooms(rooms),
      ),
    };
  }

  static HouseProfile twoA({String id = 'local-2a', String inviteCode = ''}) {
    const people = [
      Person(id: 'nimesh', name: 'Nimesh', roomId: 1),
      Person(id: 'mansi', name: 'Mansi', roomId: 1),
      Person(id: 'roshan', name: 'Roshan', roomId: 2),
      Person(id: 'sudhir', name: 'Sudhir', roomId: 2),
      Person(id: 'kartik', name: 'Kartik', roomId: 3),
      Person(id: 'nayan', name: 'Nayan', roomId: 3),
    ];
    const rooms = [
      HouseRoom(id: 1, name: 'Room 1', colorValue: 0xFF2563EB),
      HouseRoom(id: 2, name: 'Room 2', colorValue: 0xFF16A34A),
      HouseRoom(id: 3, name: 'Room 3', colorValue: 0xFFEA580C),
    ];
    return HouseProfile(
      id: id,
      name: '2A House',
      inviteCode: inviteCode,
      rooms: rooms,
      people: people,
      rules: {
        JobType.downstairs: JobRule(
          type: JobType.downstairs,
          title: JobType.downstairs.title,
          blurb: JobType.downstairs.blurb,
          checklist: JobType.downstairs.checklist,
          weekdays: const [DateTime.wednesday, DateTime.sunday],
          cycle: const [1, 2, 3],
          epoch: DateTime(2026, 8, 19),
        ),
        JobType.upstairs: JobRule(
          type: JobType.upstairs,
          title: JobType.upstairs.title,
          blurb: JobType.upstairs.blurb,
          checklist: JobType.upstairs.checklist,
          weekdays: const [DateTime.sunday],
          cycle: const [3, 2, 1],
          epoch: DateTime(2026, 8, 23),
        ),
        JobType.garbage: JobRule(
          type: JobType.garbage,
          title: JobType.garbage.title,
          blurb: JobType.garbage.blurb,
          checklist: JobType.garbage.checklist,
          weekdays: const [
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          ],
          cycle: const [1, 2, 3],
          epoch: DateTime(2026, 8, 17),
          sundayFollowsUpstairs: true,
          weekdayRooms: const {
            DateTime.monday: 3,
            DateTime.tuesday: 3,
            DateTime.wednesday: 1,
            DateTime.thursday: 1,
            DateTime.friday: 2,
            DateTime.saturday: 2,
          },
        ),
      },
    );
  }

  static HouseProfile blank({
    required String id,
    required String name,
    required String inviteCode,
    required List<HouseRoom> rooms,
    required List<Person> people,
    List<String> memberUids = const [],
    DateTime? start,
  }) {
    final ids = rooms.map((r) => r.id).toList();
    return HouseProfile(
      id: id,
      name: name,
      inviteCode: inviteCode,
      rooms: rooms,
      people: people,
      memberUids: memberUids,
      rules: {
        for (final type in JobType.values)
          type: defaultRule(type, ids, start: start),
      },
    );
  }
}

DateTime? _parseTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value as String);
}
