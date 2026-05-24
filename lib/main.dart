import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // FCM package thak
import 'login_screen.dart';
import 'main_nav.dart';

// App kikhak cip lai (Background) a Noti hong lut ciang a dawng ding function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Hih mun ah background noti a lut ciang a nasep ding te kigelh thei hi
  debugPrint("Background Noti lut hi: ${message.messageId}");
}

void main() async {
  // Screen mial loh na ding data ngakna
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase on na
  await Firebase.initializeApp();

  // FCM Background on-na (App kikhak lai a noti ngah theihna)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // User kiang ah Noti pusuak theihna phalna (Permission) ngetna
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const LiveStreamApp());
}

class LiveStreamApp extends StatelessWidget {
  const LiveStreamApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'World Cup Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.greenAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      // Login dinmun check na
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
            );
          }
          if (snapshot.hasData) {
            return const MainNav(); // Login khinsa hileh
          }
          return const LoginScreen(); // Login khin lo hileh
        },
      ),
    );
  }
}