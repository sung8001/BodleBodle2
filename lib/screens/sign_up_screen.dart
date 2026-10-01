//회원가입
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user_model.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/hover_underline_text.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final Color _blackColor = const Color(0xFF000000);

  // 가상 기존 아이디 목록 (아이디 중복 검사용)
  final List<String> _existingIds = ['admin', 'povie_user', 'test1234'];

  @override
  void dispose() {
    _emailController.dispose();
    _idController.dispose();
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 회원가입 검증 및 데이터 처리 함수
  void _handleSignUp() {
    final email = _emailController.text.trim();
    final id = _idController.text.trim();
    final nickname = _nicknameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    List<String> errorMessages = [];

    // 이메일 정규식 검사
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    // 1. 빈 칸 검사
    if (email.isEmpty ||
        id.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      errorMessages.add('• 모든 항목을 입력해 주세요.');
    } else {
      // 2. 이메일 형식 상세 검사 (간소화된 문구)
      if (!emailRegex.hasMatch(email)) {
        errorMessages.add('• 올바른 이메일 형식이 아닙니다.');
      }

      // 3. 아이디 중복 검사 (닉네임은 중복 허용)
      if (_existingIds.contains(id)) {
        errorMessages.add('• 이미 사용 중인 아이디입니다.');
      }

      // 4. 비밀번호 일치 검사
      if (password != confirmPassword) {
        errorMessages.add('• 비밀번호가 일치하지 않습니다.');
      }
    }

    // 오류가 있으면 검은색 스낵바 출력
    if (errorMessages.isNotEmpty) {
      _showErrorSnackBar(errorMessages.join('\n'));
      return;
    }

    // 모든 검증 통과 -> UserModel 생성
    final newUser = UserModel(email: email, id: id, nickname: nickname);
    debugPrint('새 회원가입 유저 데이터 생성 완료: ${newUser.toJson()}');

    // 성공 메시지 출력 및 기다림 없이 즉시 로그인 화면으로 전환
    _showSuccessSnackBar('회원가입이 완료되었습니다!');
    Navigator.of(context).pop();
  }

  // 실패/오류 알림 스낵바 (검은색 배경)
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _blackColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 성공 알림 스낵바 (차분한 정답 초록 배경 + 체크 아이콘)
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 상단 헤더
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: _blackColor,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
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
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 회원가입 폼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '회원가입',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. 이메일
                    CustomInputField(
                      controller: _emailController,
                      hintText: '이메일',
                      icon: Icons.email_outlined,
                      blackColor: _blackColor,
                    ),

                    const SizedBox(height: 14),

                    // 2. 아이디
                    CustomInputField(
                      controller: _idController,
                      hintText: '아이디',
                      icon: Icons.person_outline,
                      blackColor: _blackColor,
                    ),

                    const SizedBox(height: 14),

                    // 3. 닉네임
                    CustomInputField(
                      controller: _nicknameController,
                      hintText: '닉네임',
                      icon: Icons.badge_outlined,
                      blackColor: _blackColor,
                    ),

                    const SizedBox(height: 14),

                    // 4. 비밀번호
                    CustomInputField(
                      controller: _passwordController,
                      hintText: '비밀번호',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      blackColor: _blackColor,
                    ),

                    const SizedBox(height: 14),

                    // 5. 비밀번호 확인
                    CustomInputField(
                      controller: _confirmPasswordController,
                      hintText: '비밀번호 확인',
                      icon: Icons.lock_reset,
                      isPassword: true,
                      blackColor: _blackColor,
                    ),

                    const SizedBox(height: 28),

                    // 가입하기 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blackColor,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text(
                          '가입하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 로그인으로 돌아가기
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '이미 계정이 있으신가요? ',
                          style: TextStyle(color: _blackColor, fontSize: 14),
                        ),
                        HoverUnderlineText(
                          text: '로그인하기',
                          style: TextStyle(
                            color: _blackColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
