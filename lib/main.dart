import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:permission_handler/permission_handler.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/main/home_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  debugPrint('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Stripe nan try/catch — pa bloke app si MainActivity pa bon
  try {
    Stripe.publishableKey =
    'pk_live_51SkeFRQaU20v1ixWGKe4bf6KRToOBEMPsIKH1tlJjlAkchp6j6lw2QPNoKq7lLbx7qpt1tYZeg7ynn2NE5Twp5lT00IhxnnALC';
    await Stripe.instance.applySettings();
  } catch (e) {
    debugPrint('Stripe init error: $e');
  }

  _requestEssentialPermissions();

  runApp(const LesbieChatApp());
}

Future<void> _requestEssentialPermissions() async {
  try {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.photos,
      Permission.storage,
    ].request();
  } catch (e) {
    debugPrint('Permission error: $e');
  }
}

class LesbieChatApp extends StatelessWidget {
  const LesbieChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lesbie Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      color: const Color(0xFF07070B),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
          alert: true, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token != null) await _saveFcmToken(token);
      messaging.onTokenRefresh.listen(_saveFcmToken);
      FirebaseMessaging.onMessage.listen((m) {
        debugPrint('Foreground: ${m.notification?.title}');
      });
      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        debugPrint('Opened: ${m.data}');
      });
    } catch (e) {
      debugPrint('FCM setup error: $e');
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fcmToken': token,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Save FCM token error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return _UserRouter(uid: snapshot.data!.uid);
        }
        return const SplashScreen();
      },
    );
  }
}

class _UserRouter extends StatefulWidget {
  final String uid;
  const _UserRouter({required this.uid});

  @override
  State<_UserRouter> createState() => _UserRouterState();
}

class _UserRouterState extends State<_UserRouter> {
  late Future<DocumentSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadUser();
  }

  Future<DocumentSnapshot> _loadUser() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get()
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw Exception('Timeout'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          debugPrint('UserRouter error: ${snapshot.error}');
          return const SplashScreen();
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data?['onboardingComplete'] == true) {
            return const HomeScreen();
          }
          return const SplashScreen();
        }
        return const SplashScreen();
      },
    );
  }
}