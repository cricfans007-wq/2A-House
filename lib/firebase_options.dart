// Generated for the 2A House Firebase project (twoa-house-chores).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is wired for Android, iOS, and web. This platform is skipped.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBIk8n8LpBoLiwoopYomVd4UqPMnZHjoP0',
    appId: '1:848257040568:web:5499c27211068b8997344d',
    messagingSenderId: '848257040568',
    projectId: 'twoa-house-chores',
    authDomain: 'twoa-house-chores.firebaseapp.com',
    storageBucket: 'twoa-house-chores.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBd4xxXs3VcHNJ92nx_OHDXqKoqEmaYmCU',
    appId: '1:848257040568:android:4f7e260776985e5697344d',
    messagingSenderId: '848257040568',
    projectId: 'twoa-house-chores',
    storageBucket: 'twoa-house-chores.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBHSDcep6yEDHCpFgZbXkusGozwWo5TliI',
    appId: '1:848257040568:ios:53c7045bbb65c51d97344d',
    messagingSenderId: '848257040568',
    projectId: 'twoa-house-chores',
    storageBucket: 'twoa-house-chores.firebasestorage.app',
    iosBundleId: 'com.house.houseChores',
  );
}
