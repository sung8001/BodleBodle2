//첫화면&로그인화면
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:async';

import '../widgets/custom_input_field.dart';
import '../widgets/hover_underline_text.dart';
import 'sign_up_screen.dart';

class MainWrapperScreen extends StatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  State<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends State<MainWrapperScreen> {
  double _splashOpacity = 0.0;
  double _loginOpacity = 0.0;
  double _loginScale = 1.03;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Color _blackColor = const Color(0xFF000000);

  @override
  void initState() {
    super.initState();

    Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _splashOpacity = 1.0);
    });

    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _splashOpacity = 0.0);
    });

    Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _loginOpacity = 1.0;
          _loginScale = 1.0;
        });
      }
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
          // 1. 로그인 화면 레이어
          AnimatedScale(
            scale: _loginScale,
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _loginOpacity,
              duration: const Duration(milliseconds: 2000),
              curve: Curves.easeInOut,
              child: SafeArea(
                child: Column(
                  children: [
                    // 상단 헤더 영역
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
                            icon: Icon(
                              Icons.menu,
                              size: 32,
                              color: _blackColor,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                    // 로그인 폼 영역
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        children: [
                          // 아이디 입력창
                          CustomInputField(
                            controller: _idController,
                            hintText: '아이디',
                            icon: Icons.person,
                            blackColor: _blackColor,
                          ),

                          const SizedBox(height: 16),

                          // 비밀번호 입력창
                          CustomInputField(
                            controller: _passwordController,
                            hintText: '비밀번호',
                            icon: Icons.lock,
                            isPassword: true,
                            blackColor: _blackColor,
                          ),

                          const SizedBox(height: 12),

                          // 아이디/비밀번호 찾기
                          HoverUnderlineText(
                            text: '아이디 / 비밀번호 찾기',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            onTap: () {},
                          ),

                          const SizedBox(height: 24),

                          // 로그인 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {},
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

                          // 회원가입 이동 영역
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
                              HoverUnderlineText(
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
            ),
          ),

          // 2. 스플래시 로고 레이어
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
