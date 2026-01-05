import 'package:bump/features/bump/bump_screen.dart';
import 'package:bump/features/card/card_detail_screen.dart';
import 'package:bump/features/editor/card_editor_screen.dart';
import 'package:bump/features/history/history_screen.dart';
import 'package:bump/features/profile/profile_setup_screen.dart';
import 'package:bump/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ProviderScope(child: BumpApp()));
}

// Router configuration
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
  ],
);

class BumpApp extends ConsumerWidget {
  const BumpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Bump',
      theme: ThemeData(
        brightness: Brightness.dark, // Default to dark mode
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
