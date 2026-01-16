import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // [필수] 패키지 import
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); 

  // ------------------------------------------------------------------
  // [1] Google 로그인 함수
  // ------------------------------------------------------------------
  Future<User?> signInWithGoogle() async {
    try {
      // 1. 구글 로그인 팝업
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) return null; // 사용자가 취소함

      // 2. 인증 토큰 확보
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Firebase 자격 증명 생성
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase 로그인
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Google 로그인 에러: $e");
      return null;
    }
  }

  // ------------------------------------------------------------------
  // [2] Apple 로그인 함수
  // ------------------------------------------------------------------
  Future<User?> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final sha256Nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Nonce,
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'applebump', 
          redirectUri: Uri.parse(
            'https://bump-57bb6.firebaseapp.com/__/auth/handler', 
          ),
        ),
      );

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (appleCredential.givenName != null) {
        final name = "${appleCredential.familyName ?? ''}${appleCredential.givenName ?? ''}";
        print("Apple User Name: $name");
      }

      return userCredential.user;

    } catch (e) {
      print("Apple 로그인 에러: $e");
      return null;
    }
  }

  // ------------------------------------------------------------------
  // [3] 유틸리티 함수 (Nonce 생성)
  // ------------------------------------------------------------------
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  } 

  Future<void> signOut() async {
    try {
      // 구글/애플 로그인 세션도 함께 종료해야 완벽한 로그아웃이 됩니다.
      await _googleSignIn.signOut();
      // await SignInWithApple. // 애플은 별도 API 없음 (Firebase signOut으로 충분)
      await _auth.signOut();
    } catch (e) {
      print("로그아웃 실패: $e");
      rethrow;
    }
  }

  // [추가 2] 회원 탈퇴 (계정 삭제)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("로그인된 사용자가 없습니다.");

      // 1. Firestore 데이터 삭제 (필요한 컬렉션 모두 삭제)
      // 예: users 컬렉션, bump_requests 등
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      
      // 2. Firebase Auth 계정 삭제
      // 주의: 로그인한 지 오래되면 'requires-recent-login' 에러가 날 수 있음 (이 경우 재로그인 유도 필요)
      await user.delete(); 
      
      // 3. 로그아웃 처리
      await _googleSignIn.signOut();
    } catch (e) {
      print("회원 탈퇴 실패: $e");
      rethrow;
    }
  }
} 