import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart'; // TargetPlatform 사용을 위해

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Apple 로그인 메인 함수
  Future<User?> signInWithApple() async {
    try {
      // 1. Nonce(난수) 생성: 보안상 필수 (Replay Attack 방지)
      final rawNonce = _generateNonce();
      final sha256Nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // 2. Apple에 인증 요청
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Nonce, // 해싱된 nonce 전달
        
        // [Android/Web 지원을 위한 설정]
        webAuthenticationOptions: WebAuthenticationOptions(
          // 아까 만든 Service ID (Identifier)
          clientId: 'applebump', 
          
          // Firebase Console에 있던 콜백 URL
          redirectUri: Uri.parse(
            'https://bump-57bb6.firebaseapp.com/__/auth/handler', 
          ),
        ),
      );

      // 3. Apple 인증 정보로 Firebase Credential 생성
      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode, // 웹/Android 흐름에서 중요
        rawNonce: rawNonce, // 해싱되지 않은 원본 nonce 전달
      );

      // 4. Firebase에 로그인
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // [중요] 최초 로그인 시에만 이름(fullName) 정보가 제공됨
      // 이름 정보가 있다면 Firestore 등에 저장하는 로직 필요
      if (appleCredential.givenName != null) {
        final name = "${appleCredential.familyName ?? ''}${appleCredential.givenName ?? ''}";
        print("Apple User Name: $name");
        // TODO: 여기서 Firestore에 이름 저장 (예: updateProfile)
      }

      return userCredential.user;

    } catch (e) {
      print("Apple 로그인 에러: $e");
      return null;
    }
  }

  // Nonce 생성 헬퍼 함수
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }
}