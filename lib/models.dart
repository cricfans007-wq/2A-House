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
  const AppSettings({this.myPersonId, this.notifyHour = 20});

  final String? myPersonId;
  final int notifyHour;

  AppSettings copyWith({
    String? myPersonId,
    int? notifyHour,
    bool clearPerson = false,
  }) => AppSettings(
    myPersonId: clearPerson ? null : (myPersonId ?? this.myPersonId),
    notifyHour: notifyHour ?? this.notifyHour,
  );

  Map<String, dynamic> toMap() => {
    'myPersonId': myPersonId,
    'notifyHour': notifyHour,
  };

  factory AppSettings.fromMap(Map map) => AppSettings(
    myPersonId: map['myPersonId'] as String?,
    notifyHour: (map['notifyHour'] as int?) ?? 20,
  );
}

DateTime? _parseTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value as String);
}
