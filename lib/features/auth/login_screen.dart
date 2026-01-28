import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        debugPrint("Google 로그인 취소 또는 실패");
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

  Future<void> _handleAnonymousLogin() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': 'Guest', 
          'email': '',            
          'photoURL': '',         
          'isAnonymous': true,    
          'createdAt': FieldValue.serverTimestamp(), 
        });

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

  Future<void> _handleAppleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithApple();

      if (user != null) {
        if (mounted) context.go('/');
      } else {
        debugPrint("Apple 로그인 취소 또는 실패");
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
                  
                  // [수정된 부분] 앱 로고 이미지 적용
                  Container(
                    width: 140, 
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35), // 둥근 모서리
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.asset(
                        'assets/icon/app_icon.png', // 여기에 준비한 이미지가 뜹니다
                        fit: BoxFit.cover,
                      ),
                    ),
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
                  _buildLoginButton(
                    icon: FontAwesomeIcons.apple, // 애플 로고
                    label: "Sign in with Apple",
                    onTap: _handleAppleLogin,
                    color: Colors.white,
                    textColor: Colors.black,
                  ),
                  
                  const SizedBox(height: 16),

                  // 2. Google Login Button
                  _buildLoginButton(
                    icon: FontAwesomeIcons.google, // 구글 로고 (g_mobiledata보다 훨씬 예쁨)
                    label: "Sign in with Google",
                    onTap: _handleGoogleLogin,
                    color: Colors.white, 
                    textColor: Colors.black, 
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 3. Guest Login Button
                  _buildLoginButton(
                    icon: Icons.person, // 일반 아이콘
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