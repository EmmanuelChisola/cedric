import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:securecom/features/app/spla_scree/spla_sc.dart';
import 'package:securecom/features/user_auth/presentation/pages/add_announcements.dart';
import 'package:securecom/features/user_auth/presentation/pages/login_pg.dart';
import 'package:securecom/features/user_auth/presentation/pages/members.dart';
import 'package:securecom/features/user_auth/presentation/pages/profile_page.dart';
import 'package:securecom/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:securecom/forms.dart';
import 'package:securecom/home.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyBsTqDxPBU5Bn96MnZkIumeCDped5XysmQ",
          appId: "1:1060843900032:web:a1dc2c77096625ed95ea65",
          messagingSenderId: "1060843900032",
          projectId: "seccom-f64b5"),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const KBCApp());

}

class KBCApp extends StatelessWidget {
  const KBCApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KBConnect',
      initialRoute: '/',
      routes: {
        '/': (context) => const Splashscreen(child: LoginPg()),
        '/login': (context) => const LoginPg(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => ChurchHomePage(),
        '/members': (context) => MembersPage(),
        '/forms': (context) => const FormsPage(),
        '/profile': (context) => ProfileScreen(),
        '/announcements': (context) => AddAnnouncement(),
      },
    );
  }
}