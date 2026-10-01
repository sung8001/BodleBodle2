//앱실행
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/main_wrapper_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: MainWrapperScreen(),
    );
  }
}
