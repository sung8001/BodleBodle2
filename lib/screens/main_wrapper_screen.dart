import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:async';

import '../widgets/clickable_text.dart';
import '../widgets/custom_input_field.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'sign_up_screen.dart';

enum AppStep { splash, onboarding, login }

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  AppStep _currentStep = AppStep.splash;
  double _splashOpacity = 0.0;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Color _blackColor = const Color(0xFF000000);

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _splashOpacity = 1.0);
    });

    Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _splashOpacity = 0.0;
        });
      }
    });

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        setState(() {
          _currentStep = AppStep.onboarding;
        });
      }
    });
  }

  void _goToLogin() {
    setState(() {
      _currentStep = AppStep.login;
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (_currentStep == AppStep.login)
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 48),
                        const Spacer(),
                        Text(
                          'POV-IE',
                          style: GoogleFonts.anton(
                            color: _blackColor,
                            fontSize: 28,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.menu, size: 32, color: _blackColor),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 1),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        CustomInputField(
                          controller: _idController,
                          hintText: '아이디',
                          icon: Icons.person,
                          blackColor: _blackColor,
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          controller: _passwordController,
                          hintText: '비밀번호',
                          icon: Icons.lock,
                          isPassword: true,
                          blackColor: _blackColor,
                        ),
                        const SizedBox(height: 12),
                        ClickableText(
                          text: '아이디 / 비밀번호 찾기',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          onTap: () {},
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (
                                    context,
                                    animation,
                                    secondaryAnimation,
                                  ) => const HomeScreen(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _blackColor,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Text(
                              '로그인',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '계정이 없으신가요? ',
                              style: TextStyle(
                                color: _blackColor,
                                fontSize: 14,
                              ),
                            ),
                            ClickableText(
                              text: '회원가입하기',
                              style: TextStyle(
                                color: _blackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    pageBuilder: (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                    ) => const SignUpScreen(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),

          if (_currentStep == AppStep.onboarding)
            OnboardingScreen(onComplete: _goToLogin),

          if (_currentStep == AppStep.splash)
            IgnorePointer(
              ignoring: _splashOpacity == 0.0,
              child: AnimatedOpacity(
                opacity: _splashOpacity,
                duration: const Duration(milliseconds: 1800),
                curve: Curves.easeInOut,
                child: Center(
                  child: Text(
                    'POV-IE',
                    style: GoogleFonts.anton(
                      color: _blackColor,
                      fontSize: 56,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
