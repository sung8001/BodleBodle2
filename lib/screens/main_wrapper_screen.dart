import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:async';

import '../widgets/clickable_text.dart';
import '../widgets/custom_input_field.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'sign_up_screen.dart';
import '../services/auth_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

enum AppStep { splash, onboarding, login }

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  AppStep _currentStep = AppStep.splash;
  double _splashOpacity = 0.0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Color _blackColor = const Color(0xFF000000);
  bool _isLoggingIn = false;

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
    if (!mounted) return;

    // 이미 로그인한 사용자라면 홈으로 이동
    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
    // 로그인하지 않았다면 기존 온보딩 화면으로 이동
      setState(() {
        _currentStep = AppStep.onboarding;
      });
    }
  });
;
  }

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력해 주세요.')),
      );
      return;
    }

    setState(() => _isLoggingIn = true);
    try {
      await AuthService().login(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.readableError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  void _goToLogin() {
    setState(() {
      _currentStep = AppStep.login;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                          controller: _emailController,
                          hintText: '이메일',
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
                            onPressed: _isLoggingIn ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _blackColor,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(
                              _isLoggingIn ? '로그인 중...' : '로그인',
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
                              onTap: () async {
                                final signedUp = await Navigator.of(context).push<bool>(
                                  PageRouteBuilder<bool>(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        const SignUpScreen(),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                                        FadeTransition(opacity: animation, child: child),
                                  ),
                                );
                                if (!mounted) return;
                                if (signedUp == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('회원가입이 완료되었습니다. 이메일로 로그인해 주세요.'),
                                    ),
                                  );
                                }
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
