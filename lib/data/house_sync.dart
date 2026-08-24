import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models.dart';
import 'house_store.dart';
import 'notifications.dart';

class HouseSync {
  HouseSync(this.store);

  static const houseId = '2a-house';

  final HouseStore store;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  var _primed = false;
  var connected = false;
  var _starting = false;
  Timer? _retry;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('houses')
      .doc(houseId)
      .collection('occurrences');

  static Future<bool> initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
      return false;
    }
  }

  Future<bool> start() async {
    if (_starting) return connected;
    _starting = true;
    _retry?.cancel();
    try {
      if (!await initializeFirebase()) {
        _fail('Couldn’t start Firebase on this phone');
        return false;
      }
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      store.cloudPush = push;
      await _sub?.cancel();
      _sub = _col.snapshots().listen(
        _onSnapshot,
        onError: (e) {
          debugPrint('House sync listen failed: $e');
          _fail('House board blocked — will retry');
          _scheduleRetry();
        },
      );
      connected = true;
      store.setCloudConnected(true);
      return true;
    } catch (e) {
      debugPrint('House sync start failed: $e');
      _fail(_messageFor(e));
      _scheduleRetry();
      return false;
    } finally {
      _starting = false;
    }
  }

  void _fail(String message) {
    connected = false;
    store.setCloudConnected(false, error: message);
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 4), () {
      unawaited(start());
    });
  }

  static String _messageFor(Object e) {
    final text = e.toString();
    if (text.contains('operation-not-allowed') ||
        text.contains('OPERATION_NOT_ALLOWED') ||
        text.contains('admin-restricted-operation')) {
      return 'Anonymous sign-in is off in Firebase';
    }
    if (text.contains('network') ||
        text.contains('unavailable') ||
        text.contains('SocketException')) {
      return 'No path to the house board';
    }
    return 'Couldn’t join the house board';
  }

  Future<void> push(Occurrence occ) async {
    if (!connected) return;
    try {
      await _col.doc(occ.id).set(occ.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('House sync push failed: $e');
    }
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    try {
      if (!_primed) {
        for (final doc in snap.docs) {
          store.applyRemote(Occurrence.fromMap(doc.data()));
        }
        _primed = true;
        connected = true;
        store.setCloudConnected(true);
        return;
      }
      for (final change in snap.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        if (change.type == DocumentChangeType.removed) continue;
        final occ = Occurrence.fromMap(data);
        final before = store.storedOccurrence(occ.id);
        store.applyRemote(occ);
        pingIfSomeoneElseFinished(store: store, before: before, after: occ);
        pingIfSomeoneElseNotified(store: store, before: before, after: occ);
      }
    } catch (e) {
      debugPrint('House sync snapshot parse failed: $e');
    }
  }

  Future<void> dispose() async {
    _retry?.cancel();
    await _sub?.cancel();
  }
}

void pingIfSomeoneElseNotified({
  required HouseStore store,
  required Occurrence? before,
  required Occurrence after,
}) {
  if (!after.notifiedOnTime) return;
  if (before?.notifiedOnTime == true) return;
  final me = store.settings.myPersonId;
  if (after.notifiedById != null && after.notifiedById == me) return;
  final who =
      store.personById(after.notifiedById)?.name ??
      'Room ${after.assignedRoom}';
  NotificationService.instance.showHouseUpdate(
    title: '$who can’t do ${after.jobType.title} today',
    body:
        'No 2× — they told the house on time. ${store.namesForRoom(after.assignedRoom)}',
  );
}

void pingIfSomeoneElseFinished({
  required HouseStore store,
  required Occurrence? before,
  required Occurrence after,
}) {
  if (!after.completed) return;
  if (before?.completed == true) return;
  final me = store.settings.myPersonId;
  if (after.completedById != null && after.completedById == me) return;
  final who =
      store.personById(after.completedById)?.name ??
      'Room ${after.assignedRoom}';
  NotificationService.instance.showHouseUpdate(
    title: '$who finished ${after.jobType.title}',
    body: store.namesForRoom(after.assignedRoom),
  );
}
