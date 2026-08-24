import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';
import 'house_store.dart';
import 'rotation.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;
  var permissionGranted = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    if (kIsWeb) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Don't ask here — Android needs an Activity, which exists only after runApp.
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
    permissionGranted = await isEnabled();
  }

  Future<bool> isEnabled() async {
    if (kIsWeb || !_ready) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final opts = await _ios?.checkPermissions();
      return opts?.isEnabled ?? false;
    }
    return await _android?.areNotificationsEnabled() ?? false;
  }

  /// Call after the first frame so the OS dialog can appear.
  Future<bool> requestPermission() async {
    if (kIsWeb || !_ready) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      permissionGranted =
          await _ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return permissionGranted;
    }
    permissionGranted =
        await _android?.requestNotificationsPermission() ?? false;
    return permissionGranted;
  }

  Future<void> showHouseUpdate({
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    await _plugin.show(
      10000 + (title.hashCode & 0xffff),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'house_done',
          'House updates',
          channelDescription: 'When someone finishes a chore or tells the house',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showTest() async {
    if (!_ready) return;
    await _plugin.show(
      9001,
      '2A House',
      'Reminders are on. You’ll get a ping the night before your jobs.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chores',
          'House chores',
          channelDescription: 'Reminders for downstairs, upstairs, and garbage',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  final _reminderIds = <int>[];

  Future<void> resync(HouseStore store) async {
    if (!_ready) return;
    for (final id in _reminderIds) {
      await _plugin.cancel(id);
    }
    _reminderIds.clear();
    final me = store.me;
    if (me == null) return;
    if (!await isEnabled()) return;

    final today = dateOnly(DateTime.now());
    var id = 1;
    for (final day in daysInRange(today, addDays(today, 13))) {
      for (final occ in store.occurrencesOn(day)) {
        if (occ.assignedRoom != me.roomId) continue;
        if (occ.completed) continue;
        await _schedule(
          id: id++,
          when: _eveningBefore(day, store.settings.notifyHour),
          title: 'Tomorrow: ${occ.jobType.title}',
          body: _body(store, occ, prefix: 'Tomorrow'),
        );
        await _schedule(
          id: id++,
          when: _morningOf(day),
          title: 'Today: ${occ.jobType.title}',
          body: _body(store, occ, prefix: 'Today'),
        );
      }
    }
  }

  String _body(HouseStore store, Occurrence occ, {required String prefix}) {
    final makeup = occ.isMakeup ? 'Makeup · ' : '';
    return '$prefix $makeup${occ.jobType.title} — ${store.namesForRoom(occ.assignedRoom)}. ${occ.jobType.blurb}';
  }

  tz.TZDateTime _eveningBefore(DateTime day, int hour) {
    final local = tz.TZDateTime.from(addDays(dateOnly(day), -1), tz.local);
    return tz.TZDateTime(tz.local, local.year, local.month, local.day, hour);
  }

  tz.TZDateTime _morningOf(DateTime day) {
    final d = dateOnly(day);
    return tz.TZDateTime(tz.local, d.year, d.month, d.day, 9);
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
  }) async {
    if (when.isBefore(tz.TZDateTime.now(tz.local))) return;
    _reminderIds.add(id);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chores',
          'House chores',
          channelDescription: 'Reminders for downstairs, upstairs, and garbage',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
