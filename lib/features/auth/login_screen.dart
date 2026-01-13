import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/auth_service.dart'; // [필수] AuthService import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // 패키지 import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // [익명 로그인 처리]
  Future<void> _handleAnonymousLogin() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 실패: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // [Apple 로그인 처리] - AuthService 연결
  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    try {
      // 1. AuthService의 Apple 로그인 함수 호출
      final user = await AuthService().signInWithApple();

      if (user != null) {
        // 2. 로그인 성공 시 홈으로 이동
        if (mounted) context.go('/');
      } else {
        // 사용자가 취소했거나 실패한 경우
        print("Apple 로그인 취소 또는 실패");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("로그인 오류: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A), // Dark Blue
                    Colors.black,
                    Color(0xFF1E1E1E), // Dark Grey
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Logo
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(Icons.vibration, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "BUMP",
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "The new way to connect.",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white54,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // [수정됨] Apple Login Button (공식 위젯 사용)
                  SizedBox(
                    height: 50, // 버튼 높이 지정
                    width: double.infinity,
                    child: SignInWithAppleButton(
                      onPressed: _handleAppleLogin, // 핸들러 연결
                      // 스타일: 다크모드 배경이므로 White 버튼 사용
                      style: SignInWithAppleButtonStyle.white, 
                      // 텍스트 커스텀 (기본값은 'Sign in with Apple')
                      text: "Sign in with Apple", 
                      // 둥근 모서리 정도 (Guest 버튼과 비슷하게 맞춤)
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Guest Login (기존 디자인 유지)
                  _buildLoginButton(
                    icon: Icons.person_outline, 
                    label: "Guest Login", 
                    onTap: _handleAnonymousLogin,
                    color: Colors.white.withOpacity(0.1),
                    textColor: Colors.white,
                    isOutlined: true,
                  ),
                  
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // 커스텀 버튼 빌더 (게스트 로그인용)
  Widget _buildLoginButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    required Color color,
    required Color textColor,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50, // Apple 버튼과 높이 맞춤
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25), // Apple 버튼과 라운드 맞춤
          border: isOutlined ? Border.all(color: Colors.white30) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}