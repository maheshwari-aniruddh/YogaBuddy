import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'theme/app_colors.dart';
import 'services/notification_service.dart';
import 'screens/auth_wrapper.dart';

void main() async {
  debugPrint('main() started');
  WidgetsFlutterBinding.ensureInitialized();
  String? firebaseError;
  try {
    await Firebase.initializeApp();
    // --- Firebase test: try reading a dummy Firestore collection ---
    final snapshot = await FirebaseFirestore.instance.collection('test').get();
    debugPrint('Firestore test: Success, ${snapshot.size} docs found in "test" collection.');
  } catch (e) {
    debugPrint('Firestore test: ERROR - $e');
    firebaseError = e.toString();
  }

  // Initialize notification service
  try {
    await NotificationService().initialize();
    debugPrint('Notification service initialized');
  } catch (e) {
    debugPrint('Notification service error: $e');
  }

  runApp(MyApp(firebaseError: firebaseError));
}

class MyApp extends StatelessWidget {
  final String? firebaseError;
  const MyApp({this.firebaseError, super.key});

  @override
  Widget build(BuildContext context) {
    // Set dark status bar for premium dark mode
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0B),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Roze',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: false).copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}
