import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // [필수] Firestore import 추가
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;


  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null) {
        if (mounted) context.go('/');
      } else {
        print("Google 로그인 취소 또는 실패");
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
  // [수정됨] 익명 로그인 + Firestore 데이터 생성 처리
  Future<void> _handleAnonymousLogin() async {
    setState(() => _isLoading = true);
    try {
      // 1. 익명 로그인 시도
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // 2. [핵심] 로그인 성공 직후, Firestore에 '내 정보' 강제 저장
        // 이 과정이 있어야 상대방이 내 명함을 볼 수 있습니다.
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': 'Guest', // 이름이 없으면 화면에 안 뜨므로 기본값 지정
          'email': '',            // 이메일 없음
          'photoURL': '',         // 사진 없음
          'isAnonymous': true,    // 익명 계정 표시
          'createdAt': FieldValue.serverTimestamp(), // 가입 시간
        });

        // 3. 홈으로 이동
        if (mounted) context.go('/');
      }
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
      final user = await AuthService().signInWithApple();

      if (user != null) {
        // AuthService 내부에서 이미 Firestore 저장을 처리한다고 가정합니다.
        // 만약 AuthService에도 저장 로직이 없다면 거기도 추가해야 합니다.
        if (mounted) context.go('/');
      } else {
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
                  
                  // Apple Login Button
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: SignInWithAppleButton(
                      onPressed: _handleAppleLogin,
                      style: SignInWithAppleButtonStyle.white, 
                      text: "Sign in with Apple", 
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // [추가] Google Login Button (커스텀 디자인)
                  _buildLoginButton(
                    // 주의: 구글 로고 아이콘이 없다면 Icons.login 등으로 대체하거나
                    // assets에 구글 로고 png를 추가하여 Image.asset을 사용해야 합니다.
                    // 여기서는 텍스트와 아이콘으로 구성합니다.
                    icon: Icons.g_mobiledata, // 임시 아이콘 (로고 이미지 권장)
                    label: "Sign in with Google",
                    onTap: _handleGoogleLogin,
                    color: Colors.white, // Apple 버튼과 동일하게 흰색 배경
                    textColor: Colors.black, // 글자는 검은색
                    isOutlined: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Guest Login Button
                  _buildLoginButton(
                    icon: Icons.person_outline, 
                    label: "Guest Login", 
                    onTap: _handleAnonymousLogin, // 수정된 함수 연결
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
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
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