import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/shake_detector.dart';
import 'package:bump/features/home/widgets/bump_card.dart'; // [필수] 위에서 만든 위젯 import
import 'package:bump/features/home/widgets/mode_switcher.dart';
import 'package:bump/features/home/widgets/parallax_background.dart';
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
    // 흔들기 감지 시 범프 화면으로 이동
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

    // DB 키값 변환 헬퍼
    String getModeKey(int index) => ['business', 'social', 'private'][index];

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? ref.read(databaseServiceProvider).getProfileStream(user.uid)
            : null,
        builder: (context, snapshot) {
          // 1. 기본값 및 색상 설정
          Color primary = AppColors.businessPrimary;
          Color accent = AppColors.businessAccent;

          // 모드별 색상 변경
          if (currentModeIndex == 1) { 
            primary = AppColors.socialPrimary; 
            accent = AppColors.socialAccent; 
          } else if (currentModeIndex == 2) { 
            primary = AppColors.privatePrimary; 
            accent = AppColors.privateAccent; 
          }

          // 2. 명함 데이터 준비 (Map으로 정리)
          Map<String, dynamic> cardData = {};

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final profiles = data['profiles'] as Map<String, dynamic>?;
            final currentProfile = profiles?[getModeKey(currentModeIndex)];
            
            if (currentProfile != null) {
              // DB에서 가져온 데이터를 그대로 할당하거나, 필요한 필드만 추출
              cardData = {
                'name': currentProfile['name'],
                'role': currentProfile['role'],     // Business
                'bio': currentProfile['bio'],       // Social/Private
                'company': currentProfile['company'], // Business
                'location': currentProfile['location'], // Social/Private
                'phone': currentProfile['phone'],   // Business
                'email': currentProfile['email'],   // Social/Private
                'photoUrl': currentProfile['photoUrl'],
              };
            }
          }

          return Stack(
            children: [
              // 배경 (패럴랙스 효과)
              ParallaxBackground(primaryColor: primary, accentColor: accent),
              
              // 메인 콘텐츠 (명함 카드)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // [핵심] 명함 카드 위젯 표시
                      BumpCard(
                        modeIndex: currentModeIndex,
                        primaryColor: accent, // 강조색 사용
                        data: cardData,       // 준비된 데이터 전달
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // 안내 문구
                      Text(
                        "폰을 흔들어 교환하세요",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 모드 스위처
              Positioned(
                bottom: 50, left: 20, right: 20,
                child: ModeSwitcher(
                  currentMode: currentModeIndex,
                  onModeChanged: (idx) => ref.read(modeProvider.notifier).state = idx,
                ),
              ),

              // 우측 상단: 프로필 편집 버튼
              Positioned(
                top: 50, right: 20,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => context.push('/profile'), // 혹은 /editor
                ),
              ),

              // 좌측 상단: 히스토리 버튼
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