import 'dart:async';
import 'dart:math';

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

  final HouseStore store;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _occSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _houseSub;
  var _primed = false;
  var connected = false;
  var _starting = false;
  Timer? _retry;

  CollectionReference<Map<String, dynamic>>? _occCol(String houseId) =>
      FirebaseFirestore.instance
          .collection('houses')
          .doc(houseId)
          .collection('occurrences');

  DocumentReference<Map<String, dynamic>> _houseDoc(String houseId) =>
      FirebaseFirestore.instance.collection('houses').doc(houseId);

  DocumentReference<Map<String, dynamic>> _inviteDoc(String code) =>
      FirebaseFirestore.instance.collection('invites').doc(code);

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

  Future<String?> _ensureAuth() async {
    if (!await initializeFirebase()) return null;
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static String newId(String prefix) {
    final r = Random.secure().nextInt(1 << 32).toRadixString(36);
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$r';
  }

  static String inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<bool> start() async {
    if (_starting) return connected;
    _starting = true;
    _retry?.cancel();
    try {
      final uid = await _ensureAuth();
      if (uid == null) {
        _fail('Couldn’t start Firebase on this phone');
        return false;
      }
      final houseId = store.settings.houseId;
      if (houseId == null || houseId.isEmpty) {
        connected = false;
        store.setCloudConnected(false, error: 'Join or create a house first');
        return false;
      }
      store.cloudPush = push;
      store.cloudPushHouse = pushHouse;
      await _houseSub?.cancel();
      await _occSub?.cancel();
      _primed = false;
      _houseSub = _houseDoc(houseId).snapshots().listen(
        (snap) {
          final data = snap.data();
          if (data == null) return;
          store.applyRemoteHouse(HouseProfile.fromMap(data));
        },
        onError: (e) {
          debugPrint('House listen failed: $e');
          _fail('House board blocked — will retry');
          _scheduleRetry();
        },
      );
      _occSub = _occCol(houseId)!.snapshots().listen(
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

  Future<void> stop() async {
    _retry?.cancel();
    _retry = null;
    await _houseSub?.cancel();
    await _occSub?.cancel();
    _houseSub = null;
    _occSub = null;
    connected = false;
    store.cloudPush = null;
    store.cloudPushHouse = null;
    store.setCloudConnected(false);
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
    if (text.contains('permission-denied')) {
      return 'Couldn’t join that house — check the code';
    }
    if (text.contains('network') ||
        text.contains('unavailable') ||
        text.contains('SocketException')) {
      return 'No path to the house board';
    }
    return 'Couldn’t join the house board';
  }

  Future<HouseProfile> createHouse({
    required String name,
    required List<HouseRoom> rooms,
    required List<Person> people,
    Map<JobType, JobRule>? rules,
  }) async {
    final uid = await _ensureAuth();
    if (uid == null) {
      throw StateError('Couldn’t start Firebase on this phone');
    }
    var code = inviteCode();
    for (var i = 0; i < 8; i++) {
      final existing = await _inviteDoc(code).get();
      if (!existing.exists) break;
      code = inviteCode();
    }
    final id = newId('h');
    var profile = HouseProfile.blank(
      id: id,
      name: _clipName(name),
      inviteCode: code,
      rooms: rooms,
      people: people,
      memberUids: [uid],
    );
    if (rules != null) {
      profile = profile.copyWith(rules: rules);
    }
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_houseDoc(id), profile.toMap());
    batch.set(_inviteDoc(code), {
      'houseId': id,
      'memberUids': [uid],
    });
    await batch.commit();
    await store.adoptHouse(profile);
    unawaited(start());
    return profile;
  }

  Future<HouseProfile> joinHouse(String rawCode) async {
    final uid = await _ensureAuth();
    if (uid == null) {
      throw StateError('Couldn’t start Firebase on this phone');
    }
    final code = rawCode.trim().toUpperCase().replaceAll(' ', '');
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(code)) {
      throw StateError('Invite codes are 8 letters and numbers');
    }
    final invite = await _inviteDoc(code).get();
    if (!invite.exists) {
      throw StateError('No house uses that code');
    }
    final houseId = invite.data()?['houseId'] as String?;
    if (houseId == null || houseId.isEmpty) {
      throw StateError('That invite is incomplete');
    }
    await _inviteDoc(code).update({
      'memberUids': FieldValue.arrayUnion([uid]),
    });
    await _houseDoc(houseId).update({
      'memberUids': FieldValue.arrayUnion([uid]),
    });
    final snap = await _houseDoc(houseId).get();
    final data = snap.data();
    if (data == null) {
      throw StateError('House is missing');
    }
    final profile = HouseProfile.fromMap(data);
    await store.adoptHouse(profile);
    unawaited(start());
    return profile;
  }

  Future<void> push(Occurrence occ) async {
    final houseId = store.settings.houseId;
    if (!connected || houseId == null) return;
    try {
      await _occCol(
        houseId,
      )!.doc(occ.id).set(occ.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('House sync push failed: $e');
    }
  }

  Future<void> pushHouse(HouseProfile next) async {
    final houseId = store.settings.houseId;
    if (houseId == null || houseId.isEmpty) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final members = <String>{...next.memberUids};
      if (uid != null) members.add(uid);
      await _houseDoc(houseId).set(
        next.copyWith(memberUids: members.toList()).toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('House profile push failed: $e');
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
    await stop();
  }
}

String _clipName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'House';
  if (trimmed.length <= 40) return trimmed;
  return trimmed.substring(0, 40);
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
      store.house.roomLabel(after.assignedRoom);
  NotificationService.instance.showHouseUpdate(
    title: '$who can’t do ${store.jobTitle(after.jobType)} today',
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
      store.house.roomLabel(after.assignedRoom);
  NotificationService.instance.showHouseUpdate(
    title: '$who finished ${store.jobTitle(after.jobType)}',
    body: store.namesForRoom(after.assignedRoom),
  );
}
