//앱실행메인코드
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/main_wrapper_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleFonts.pendingFonts([GoogleFonts.anton()]);

  runApp(const PovieApp());
}

class PovieApp extends StatelessWidget {
  const PovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POV-IE',
      home: MainWrapperScreen(), // MainWrapperScreen이 스플래시->온보딩->로그인을 다 관리함
    );
  }
}

