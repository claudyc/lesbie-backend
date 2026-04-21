import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAwzVffrliEbPGlBlaDtNpdC-JmGSfB8GM',
    appId: '1:328507061507:android:9bf8b2c978a5735ecf2536',
    messagingSenderId: '328507061507',
    projectId: 'lesbie-chat',
    storageBucket: 'lesbie-chat.firebasestorage.app',
    authDomain: 'lesbie-chat.firebaseapp.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAwzVffrliEbPGlBlaDtNpdC-JmGSfB8GM',
    appId: '1:328507061507:web:d2d1a35b82a37a21cf2536',
    messagingSenderId: '328507061507',
    projectId: 'lesbie-chat',
    storageBucket: 'lesbie-chat.firebasestorage.app',
    authDomain: 'lesbie-chat.firebaseapp.com',
    measurementId: 'G-29D5KVRTRS',
  );
}