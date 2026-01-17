  // import 'package:bump/features/auth/login_screen.dart';
  // import 'package:bump/features/bump/bump_screen.dart';
  // import 'package:bump/features/card/card_detail_screen.dart';
  // import 'package:bump/features/editor/card_editor_screen.dart';
  // import 'package:bump/features/history/history_screen.dart';
  // import 'package:bump/features/profile/profile_setup_screen.dart';
  // import 'package:bump/features/home/home_screen.dart';
  // import 'package:firebase_auth/firebase_auth.dart';
  // import 'package:firebase_core/firebase_core.dart';
  // import 'package:flutter/material.dart';
  // import 'package:flutter_riverpod/flutter_riverpod.dart';
  // import 'package:go_router/go_router.dart';
  // import 'package:google_fonts/google_fonts.dart';
  // import 'package:quick_actions/quick_actions.dart';

  // // firebase_options.dart 파일이 생성되어 있어야 합니다.
  // // 터미널에서 'flutterfire configure'를 실행하면 자동 생성됩니다.
  // import 'firebase_options.dart';

  // void main() async {
  //   WidgetsFlutterBinding.ensureInitialized();

  //   // Firebase 초기화
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );

  //   // 익명 로그인 시도 (앱 시작 시 자동 로그인)
  //   // 익명 로그인 로직 제거 (LoginScreen에서 처리)
  //   // try {
  //   //   final userCredential = await FirebaseAuth.instance.signInAnonymously();
  //   //   print("Signed in with temporary account: ${userCredential.user?.uid}");
  //   // } on FirebaseAuthException catch (e) { ... }

  //   // ProviderScope는 runApp 안에 직접 전달해야 합니다.
  //   runApp(const ProviderScope(child: BumpApp()));
  // }

  // // GoRouter 설정
  // final _router = GoRouter(
  //   initialLocation: '/',
  //   routes: [
  //     GoRoute(
  //       path: '/login',
  //       builder: (context, state) => const LoginScreen(),
  //     ),
  //     GoRoute(
  //       path: '/',
  //       builder: (context, state) => const HomeScreen(),
  //     ),
  //     GoRoute(
  //       path: '/bump',
  //       builder: (context, state) => const BumpScreen(),
  //     ),
  //     GoRoute(
  //       path: '/editor',
  //       builder: (context, state) => const CardEditorScreen(),
  //     ),
  //     GoRoute(
  //       path: '/history',
  //       builder: (context, state) => const HistoryScreen(),
  //     ),
  //     GoRoute(
  //       path: '/profile',
  //       builder: (context, state) => const ProfileSetupScreen(),
  //     ),
  //     GoRoute(
  //       path: '/card_detail',
  //       builder: (context, state) {
  //         final data = state.extra as Map<String, dynamic>? ?? {};
  //         return CardDetailScreen(cardData: data);
  //       },
  //     ),
  //   ],
  //   redirect: (context, state) {
  //     final user = FirebaseAuth.instance.currentUser;
  //     final isLoggingIn = state.uri.toString() == '/login';
      
  //     if (user == null && !isLoggingIn) return '/login';
  //     if (user != null && isLoggingIn) return '/';
      
  //     return null;
  //   },
  // );

  // class BumpApp extends ConsumerWidget {
  //   const BumpApp({super.key});

  //   @override
  //   Widget build(BuildContext context, WidgetRef ref) {
  //     return MaterialApp.router(
  //       title: 'Bump',
  //       theme: ThemeData(
  //         brightness: Brightness.dark, // 다크 모드 기본 설정
  //         scaffoldBackgroundColor: Colors.black,
  //         primaryColor: Colors.white,
  //         // 구글 폰트 적용 (Outfit 폰트 사용)
  //         textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
  //           bodyColor: Colors.white,
  //           displayColor: Colors.white,
  //         ),
  //         useMaterial3: true,
  //       ),
  //       routerConfig: _router,
  //       debugShowCheckedModeBanner: false,
  //     );
  //   }
  // }


import 'package:bump/features/auth/login_screen.dart';
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
import 'package:quick_actions/quick_actions.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: BumpApp()));
}

// GoRouter 설정 (전역 변수로 유지)
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/bump',
      builder: (context, state) => const BumpScreen(),
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
        final data = state.extra as Map<String, dynamic>? ?? {};
        return CardDetailScreen(cardData: data);
      },
    ),
  ],
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggingIn = state.uri.toString() == '/login';
    
    if (user == null && !isLoggingIn) return '/login';
    if (user != null && isLoggingIn) return '/';
    
    return null;
  },
);

// [변경] ConsumerWidget -> ConsumerStatefulWidget으로 변경
// 이유: 앱 시작 시(initState) 퀵 액션을 등록하기 위해서입니다.
class BumpApp extends ConsumerStatefulWidget {
  const BumpApp({super.key});

  @override
  ConsumerState<BumpApp> createState() => _BumpAppState();
}

class _BumpAppState extends ConsumerState<BumpApp> {
  final QuickActions quickActions = const QuickActions();

  @override
  void initState() {
    super.initState();
    _setupQuickActions();
  }

  void _setupQuickActions() {
    // 1. 액션 초기화 (앱이 켜질 때 감지)
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_bump') {
        print("⚡️ 퀵액션 실행: 흔들기");
        // 전역 변수 _router를 사용하여 페이지 이동
        _router.push('/bump'); 
      } else if (shortcutType == 'action_history') {
        print("⚡️ 퀵액션 실행: 명함첩");
        _router.push('/history');
      }
    });

    // 2. 숏컷 메뉴 등록
    // 주의: 'icon_bump', 'icon_history' 이미지가 
    // android/app/src/main/res/drawable 폴더에 반드시 있어야 합니다.
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_bump',
        localizedTitle: '흔들어서 교환',
        icon: 'icon_bump', 
      ),
      const ShortcutItem(
        type: 'action_history',
        localizedTitle: '내 명함첩',
        icon: 'icon_history', 
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // 기존의 build 내용은 그대로 유지
    return MaterialApp.router(
      title: 'Bump',
      theme: ThemeData(
        brightness: Brightness.dark, 
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
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