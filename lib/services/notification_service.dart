import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Handler pou mesaj background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  print('Background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Inisyalize notifikasyon
  static Future<void> initialize() async {
    // Mande pèmisyon
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permission: ${settings.authorizationStatus}');

    // Handler pou background
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // Handler pou foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
    });

    // Sove FCM token nan Firestore
    await saveToken();

    // Rafraîchi token si li chanje
    _messaging.onTokenRefresh.listen((token) async {
      await _saveTokenToFirestore(token);
    });
  }

  // Sove token nan Firestore
  static Future<void> saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    });

    print('FCM Token saved: $token');
  }

  // Voye notifikasyon match
  static Future<void> sendMatchNotification({
    required String toUid,
    required String fromName,
  }) async {
    // Jwenn token moun ki resevwa a
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(toUid)
        .get();

    final token = doc.data()?['fcmToken'];
    if (token == null) return;

    // Sove notifikasyon nan Firestore
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'toUid': toUid,
      'type': 'match',
      'title': '🎉 Nouvo Match!',
      'body': '$fromName renmen ou tou!',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Voye notifikasyon mesaj
  static Future<void> sendMessageNotification({
    required String toUid,
    required String fromName,
    required String message,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(toUid)
        .get();

    final token = doc.data()?['fcmToken'];
    if (token == null) return;

    // Sove notifikasyon nan Firestore
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'toUid': toUid,
      'type': 'message',
      'title': '💬 $fromName',
      'body': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Jwenn kantite notifikasyon pa li
  static Stream<int> getUnreadCount(String uid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Mak tout notifikasyon kòm li
  static Future<void> markAllAsRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toUid', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .get();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}