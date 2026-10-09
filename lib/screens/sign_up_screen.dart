import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/clickable_text.dart';
import '../widgets/custom_input_field.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final Color _blackColor = const Color(0xFF000000);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_isSubmitting) return;

    final email = _emailController.text.trim();
    final id = _idController.text.trim();
    final password = _passwordController.text; // 비밀번호는 공백도 원문대로 확인
    final confirmPassword = _confirmPasswordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || id.isEmpty || password.isEmpty ||
        confirmPassword.isEmpty || name.isEmpty) {
      _showSnackBar('모든 항목을 입력해 주세요.');
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService().signUp(
        email: email,
        userId: id,
        nickname: name,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (!mounted) return;
      Navigator.pop(context, true); // 이전 로그인 화면에 가입 성공 알림
    } catch (e) {
      if (mounted) _showSnackBar(AuthService.readableError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
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
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _blackColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '회원가입',
          style: TextStyle(
            color: _blackColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
          child: Column(
            children: [
              Text(
                'POV-IE',
                style: GoogleFonts.anton(
                  color: _blackColor,
                  fontSize: 36,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              CustomInputField(
                controller: _emailController,
                hintText: '이메일',
                icon: Icons.email_outlined,
                blackColor: _blackColor,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                controller: _nameController,
                hintText: '닉네임',
                icon: Icons.person_outline,
                blackColor: _blackColor,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                controller: _idController,
                hintText: '아이디',
                icon: Icons.account_circle_outlined,
                blackColor: _blackColor,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                controller: _passwordController,
                hintText: '비밀번호',
                icon: Icons.lock_outline,
                isPassword: true,
                blackColor: _blackColor,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                controller: _confirmPasswordController,
                hintText: '비밀번호 확인',
                icon: Icons.lock_clock_outlined,
                isPassword: true,
                blackColor: _blackColor,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blackColor,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    _isSubmitting ? '가입 처리 중...' : '가입하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '이미 계정이 있으신가요? ',
                    style: TextStyle(color: _blackColor, fontSize: 14),
                  ),
                  ClickableText(
                    text: '로그인하기',
                    style: TextStyle(
                      color: _blackColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
