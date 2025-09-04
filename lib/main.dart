import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:serviceprovider/userapp/steps.dart';
import 'userapp/auth_page.dart'; // update path if different
import 'firebase_options.dart';  // generated after firebase init

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Steps(),
    );
  }
}