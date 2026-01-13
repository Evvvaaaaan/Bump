import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/shake_detector.dart';
import 'package:bump/features/home/widgets/bump_card.dart';
import 'package:bump/features/home/widgets/mode_switcher.dart';
// ParallaxBackground import 제거 (더 이상 사용하지 않음)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    String getModeKey(int index) => ['business', 'social', 'private'][index];

    return Scaffold(
      // [핵심 변경] 전체 배경을 완전한 검정색으로 설정
      backgroundColor: Colors.black, 
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? ref.read(databaseServiceProvider).getProfileStream(user.uid)
            : null,
        builder: (context, snapshot) {
          // 모드별 포인트 컬러 (텍스트나 버튼에만 살짝 사용)
          Color accentColor = AppColors.businessPrimary;
          if (currentModeIndex == 1) accentColor = AppColors.socialPrimary;
          else if (currentModeIndex == 2) accentColor = AppColors.privatePrimary;

          Map<String, dynamic> cardData = {};

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final profiles = data['profiles'] as Map<String, dynamic>?;
            final currentProfile = profiles?[getModeKey(currentModeIndex)];
            
            if (currentProfile != null) {
              cardData = {
                'name': currentProfile['name'],
                'photoUrl': currentProfile['photoUrl'],
                'style': currentProfile['style'], // [중요] 디자인 스타일 데이터 전달
                
                // 모드별 데이터 매핑
                'role': currentProfile['role'],
                'company': currentProfile['company'],
                'phone': currentProfile['phone'],
                'bio': currentProfile['bio'],
                'location': currentProfile['location'],
                'email': currentProfile['email'],
                'instagram': currentProfile['instagram'],
                'mbti': currentProfile['mbti'],
                'music': currentProfile['music'],
                'birthday': currentProfile['birthday'],
                'hobbies': currentProfile['hobbies'],
              };
            }
          }

          return Stack(
            children: [
              // 1. [New] 배경: 은은한 스포트라이트 효과
              // 완전 검정이면 너무 답답하므로, 중앙에서 약간의 빛이 퍼지는 효과를 줍니다.
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.3,
                    colors: [
                      Color(0xFF1A1A1A), // 중앙: 아주 어두운 회색 (조명 느낌)
                      Colors.black,      // 외곽: 완전 검정
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),

              // 2. 메인 컨텐츠 (명함)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // [디자인 강조] 명함이 돋보이도록 Hero 애니메이션과 그림자 효과가 적용된 BumpCard
                      Hero(
                        tag: 'my_card',
                        child: BumpCard(
                          modeIndex: currentModeIndex,
                          primaryColor: accentColor,
                          data: cardData,
                        ),
                      ),
                      const SizedBox(height: 50),
                      
                      // 안내 문구 (심플하게)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.vibration, color: Colors.white.withOpacity(0.3), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "폰을 흔들어 교환하세요",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3), 
                              fontSize: 13,
                              letterSpacing: 1.0, // 자간을 넓혀 고급스러운 느낌
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 3. 하단 모드 스위처 (배경이 어두우니 그대로 둠)
              Positioned(
                bottom: 50, left: 20, right: 20,
                child: ModeSwitcher(
                  currentMode: currentModeIndex,
                  onModeChanged: (idx) => ref.read(modeProvider.notifier).state = idx,
                ),
              ),

              // 4. 상단 버튼들 (아이콘만 깔끔하게)
              Positioned(
                top: 60, right: 20,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70), // 아웃라인 아이콘으로 변경
                  onPressed: () => context.push('/profile'),
                ),
              ),
              Positioned(
                top: 60, left: 20,
                child: IconButton(
                  icon: const Icon(Icons.history, color: Colors.white70),
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