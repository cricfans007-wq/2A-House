import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models.dart';
import 'rotation.dart';

class HouseStore extends ChangeNotifier {
  static const _peopleBox = 'people';
  static const _occBox = 'occurrences';
  static const _debtBox = 'debts';
  static const _settingsBox = 'settings';

  late Box<dynamic> _people;
  late Box<dynamic> _occurrences;
  late Box<dynamic> _debts;
  late Box<dynamic> _settings;

  AppSettings settings = const AppSettings();

  Future<void> init() async {
    _people = await Hive.openBox(_peopleBox);
    _occurrences = await Hive.openBox(_occBox);
    _debts = await Hive.openBox(_debtBox);
    _settings = await Hive.openBox(_settingsBox);
    _seedPeople();
    final raw = _settings.get('app');
    if (raw is Map) {
      settings = AppSettings.fromMap(Map<String, dynamic>.from(raw));
    }
  }

  void _seedPeople() {
    if (_people.isNotEmpty) return;
    const seed = [
      Person(id: 'nimesh', name: 'Nimesh', roomId: 1),
      Person(id: 'mansi', name: 'Mansi', roomId: 1),
      Person(id: 'roshan', name: 'Roshan', roomId: 2),
      Person(id: 'sudhir', name: 'Sudhir', roomId: 2),
      Person(id: 'kartik', name: 'Kartik', roomId: 3),
      Person(id: 'nayan', name: 'Nayan', roomId: 3),
    ];
    for (final p in seed) {
      _people.put(p.id, p.toMap());
    }
  }

  List<Person> get people {
    final list = _people.values
        .whereType<Map>()
        .map((m) => Person.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    const order = ['nimesh', 'mansi', 'roshan', 'sudhir', 'kartik', 'nayan'];
    list.sort((a, b) {
      final ai = order.indexOf(a.id);
      final bi = order.indexOf(b.id);
      return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi);
    });
    return list;
  }

  Person? personById(String? id) {
    if (id == null) return null;
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Person> peopleInRoom(int roomId) =>
      people.where((p) => p.roomId == roomId).toList();

  String namesForRoom(int roomId) {
    final names = peopleInRoom(roomId).map((p) => p.name).toList();
    if (names.isEmpty) return 'Room $roomId';
    return names.join(' & ');
  }

  Person? get me => personById(settings.myPersonId);

  var cloudConnected = false;
  String? cloudError;
  var _applyingRemote = false;
  Future<void> Function(Occurrence occ)? cloudPush;
  Future<bool> Function()? cloudReconnect;

  void setCloudConnected(bool value, {String? error}) {
    cloudConnected = value;
    cloudError = value ? null : error;
    notifyListeners();
  }

  Future<void> saveSettings(AppSettings next) async {
    settings = next;
    await _settings.put('app', next.toMap());
    notifyListeners();
  }

  Future<void> savePerson(Person person) async {
    await _people.put(person.id, person.toMap());
    notifyListeners();
  }

  Occurrence? _stored(String id) {
    final raw = _occurrences.get(id);
    if (raw is! Map) return null;
    return Occurrence.fromMap(Map<String, dynamic>.from(raw));
  }

  Occurrence hydrate(PlannedJob job, DateTime date) {
    final id = occurrenceId(date, job.jobType);
    final stored = _stored(id);
    return Occurrence(
      id: id,
      date: dateOnly(date),
      jobType: job.jobType,
      assignedRoom: stored?.assignedRoom ?? job.roomId,
      completed: stored?.completed ?? false,
      completedAt: stored?.completedAt,
      completedById: stored?.completedById,
      notifiedOnTime: stored?.notifiedOnTime ?? false,
      notifiedAt: stored?.notifiedAt,
      notifiedById: stored?.notifiedById,
      notes: stored?.notes ?? '',
    );
  }

  List<Occurrence> occurrencesOn(DateTime date) {
    final planned = jobsOn(date);
    final list = planned.map((j) => hydrate(j, date)).toList();
    list.addAll(makeupsOn(date));
    return list;
  }

  List<PenaltyDebt> get debts {
    return _debts.values
        .whereType<Map>()
        .map((m) => PenaltyDebt.fromMap(Map<String, dynamic>.from(m)))
        .toList()
      ..sort((a, b) => a.missedDate.compareTo(b.missedDate));
  }

  List<PenaltyDebt> get openDebts => debts.where((d) => !d.resolved).toList();

  List<PenaltyDebt> openDebtsForRoom(int roomId) =>
      openDebts.where((d) => d.roomId == roomId).toList();

  List<Occurrence> makeupsOn(DateTime date) {
    final d = dateOnly(date);
    final out = <Occurrence>[];
    for (final debt in openDebts) {
      final due = makeupDateFor(
        missedDate: debt.missedDate,
        jobType: debt.jobType,
        owingRoom: debt.roomId,
      );
      if (due == null || dateOnly(due) != d) continue;
      final id = occurrenceId(d, debt.jobType, makeup: true, room: debt.roomId);
      final stored = _stored(id);
      out.add(
        Occurrence(
          id: id,
          date: d,
          jobType: debt.jobType,
          assignedRoom: debt.roomId,
          completed: stored?.completed ?? false,
          completedAt: stored?.completedAt,
          completedById: stored?.completedById,
          notifiedOnTime: stored?.notifiedOnTime ?? false,
          notifiedAt: stored?.notifiedAt,
          notifiedById: stored?.notifiedById,
          isMakeup: true,
          missedDate: dateOnly(debt.missedDate),
        ),
      );
    }
    return out;
  }

  Future<void> saveOccurrence(Occurrence occ) async {
    await _occurrences.put(occ.id, occ.toMap());
    if (occ.isMakeup && occ.completed) {
      await _resolveMatchingDebt(occ);
    }
    notifyListeners();
    if (!_applyingRemote) {
      unawaited(cloudPush?.call(occ));
    }
  }

  Occurrence? storedOccurrence(String id) => _stored(id);

  void applyRemote(Occurrence occ) {
    final before = _stored(occ.id);
    if (before != null &&
        before.completed == occ.completed &&
        before.assignedRoom == occ.assignedRoom &&
        before.notifiedOnTime == occ.notifiedOnTime &&
        before.notifiedById == occ.notifiedById &&
        before.completedById == occ.completedById) {
      return;
    }
    _applyingRemote = true;
    _occurrences.put(occ.id, occ.toMap());
    _applyingRemote = false;
    if (occ.isMakeup && occ.completed) {
      _resolveMatchingDebt(occ);
    }
    notifyListeners();
  }

  Future<void> _resolveMatchingDebt(Occurrence makeup) async {
    for (final debt in openDebts) {
      if (debt.roomId != makeup.assignedRoom) continue;
      if (debt.jobType != makeup.jobType) continue;
      if (makeup.missedDate != null &&
          dateOnly(debt.missedDate) != dateOnly(makeup.missedDate!)) {
        continue;
      }
      await _debts.put(
        debt.id,
        debt.copyWith(resolved: true, makeupDate: makeup.date).toMap(),
      );
      break;
    }
  }

  Future<void> scanPenalties({DateTime? now}) async {
    final today = dateOnly(now ?? DateTime.now());
    final start = addDays(today, -90);
    var changed = false;
    for (final day in daysInRange(start, addDays(today, -1))) {
      for (final job in jobsOn(day)) {
        final occ = hydrate(job, day);
        if (occ.completed || occ.notifiedOnTime) continue;
        final id =
            'debt_${occurrenceId(day, job.jobType)}_r${occ.assignedRoom}';
        if (_debts.containsKey(id)) continue;
        await _debts.put(
          id,
          PenaltyDebt(
            id: id,
            roomId: occ.assignedRoom,
            jobType: job.jobType,
            missedDate: day,
          ).toMap(),
        );
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> resetPenalties() async {
    for (final debt in debts) {
      if (debt.resolved) continue;
      await _debts.put(debt.id, debt.copyWith(resolved: true).toMap());
    }
    notifyListeners();
  }

  bool canNotify(DateTime date, {DateTime? now}) {
    return !dateOnly(now ?? DateTime.now()).isAfter(dateOnly(date));
  }

  List<Occurrence> upcomingForPerson(
    Person person, {
    int days = 14,
    DateTime? now,
  }) {
    final start = dateOnly(now ?? DateTime.now());
    final end = addDays(start, days - 1);
    final out = <Occurrence>[];
    for (final day in daysInRange(start, end)) {
      for (final occ in occurrencesOn(day)) {
        if (occ.assignedRoom == person.roomId) out.add(occ);
      }
    }
    return out;
  }

  bool hasUpcomingBadge(Person person, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    for (final day in [today, addDays(today, 1)]) {
      if (occurrencesOn(
        day,
      ).any((o) => o.assignedRoom == person.roomId && !o.completed)) {
        return true;
      }
    }
    return false;
  }

  String notifyMessage(Occurrence occ) {
    final room = 'Room ${occ.assignedRoom} (${namesForRoom(occ.assignedRoom)})';
    final day = '${occ.date.day}/${occ.date.month}';
    return '$room can’t do ${occ.jobType.title.toLowerCase()} on $day — covering / need swap.';
  }
}
