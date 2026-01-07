import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/shake_detector.dart';
import 'package:bump/features/home/widgets/mode_switcher.dart';
import 'package:bump/features/home/widgets/parallax_background.dart';
import 'package:bump/features/home/widgets/pulse_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 현재 선택된 모드 (0:Business, 1:Social, 2:Private)
final modeProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ShakeDetector? _shakeDetector;
  
  @override
  void initState() {
    super.initState();
    _shakeDetector = ShakeDetector(onPhoneShake: () => context.push('/bump'));
    _shakeDetector?.startListening();
  }
  
  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentModeIndex = ref.watch(modeProvider);
    final user = FirebaseAuth.instance.currentUser;

    // 모드 문자열 변환 (DB 키값과 일치)
    String getModeKey(int index) => ['business', 'social', 'private'][index];

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? ref.read(databaseServiceProvider).getProfileStream(user.uid)
            : null,
        builder: (context, snapshot) {
          // 데이터가 없거나 로딩 중일 때 기본값 사용
          Color primary = AppColors.businessPrimary;
          Color accent = AppColors.businessAccent;
          String name = "Guest";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final profiles = data['profiles'] as Map<String, dynamic>?;
            final currentProfile = profiles?[getModeKey(currentModeIndex)];
            
            if (currentProfile != null) {
              name = currentProfile['name'] ?? "User";
              // 여기서 DB에 저장된 테마 색상을 가져올 수도 있음 (현재는 모드별 기본색 유지)
            }
          }

          // 모드별 기본 색상 로직 (DB에 테마값이 있다면 그걸 우선순위로 덮어쓰기 가능)
          if (currentModeIndex == 1) { primary = AppColors.socialPrimary; accent = AppColors.socialAccent; }
          else if (currentModeIndex == 2) { primary = AppColors.privatePrimary; accent = AppColors.privateAccent; }

          return Stack(
            children: [
              ParallaxBackground(primaryColor: primary, accentColor: accent),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PulseAvatar(accentColor: accent, onTap: () => context.push('/bump')),
                    const SizedBox(height: 30),
                    // 사용자 이름 표시
                    Text("Hello, $name", 
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 50, left: 20, right: 20,
                child: ModeSwitcher(
                  currentMode: currentModeIndex,
                  onModeChanged: (idx) => ref.read(modeProvider.notifier).state = idx,
                ),
              ),
              Positioned(
                top: 50, right: 20,
                child: IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () => context.push('/profile'),
                ),
              ),
              Positioned(
                top: 50, left: 20,
                child: IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: () => context.push('/history'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}