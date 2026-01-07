import 'package:bump/features/bump/bump_screen.dart';
import 'package:bump/features/card/card_detail_screen.dart';
import 'package:bump/features/editor/card_editor_screen.dart';
import 'package:bump/features/history/history_screen.dart';
import 'package:bump/features/profile/profile_setup_screen.dart';
import 'package:bump/features/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// firebase_options.dart 파일이 생성되어 있어야 합니다.
// 터미널에서 'flutterfire configure'를 실행하면 자동 생성됩니다.
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 익명 로그인 시도 (앱 시작 시 자동 로그인)
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    print("Signed in with temporary account: ${userCredential.user?.uid}");
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case "operation-not-allowed":
        print("Anonymous auth hasn't been enabled for this project.");
        break;
      default:
        print("Unknown error: ${e.message}");
    }
  }

  // ProviderScope는 runApp 안에 직접 전달해야 합니다.
  runApp(const ProviderScope(child: BumpApp()));
}

// GoRouter 설정
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/bump',
      builder: (context, state) => const BumpScreen(),
    ),
    GoRoute(
      path: '/card_detail',
      builder: (context, state) => const CardDetailScreen(),
    ),
    GoRoute(
      path: '/editor',
      builder: (context, state) => const CardEditorScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/card_detail',
      builder: (context, state) {
        // [수정] extra로 전달된 데이터를 받아서 화면에 넘겨줌
        final data = state.extra as Map<String, dynamic>? ?? {};
        return CardDetailScreen(cardData: data);
      },
    ),
  ],
);

class BumpApp extends ConsumerWidget {
  const BumpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Bump',
      theme: ThemeData(
        brightness: Brightness.dark, // 다크 모드 기본 설정
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        // 구글 폰트 적용 (Outfit 폰트 사용)
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}