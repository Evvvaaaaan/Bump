import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/shake_detector.dart';
import 'package:bump/features/home/widgets/bump_card.dart';
import 'package:bump/features/home/widgets/mode_switcher.dart';
import 'package:bump/features/home/widgets/interactive_3d_card.dart';
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
  bool _isNavigating = false; // 중복 이동 방지 플래그

  @override
  void initState() {
    super.initState();
    _shakeDetector = ShakeDetector(onPhoneShake: _handleHomeShake);
    _shakeDetector?.startListening();
  }
  
  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  // [핵심] 홈 화면 흔들기 핸들러
  Future<void> _handleHomeShake() async {
    // 1. 현재 화면이 '홈 화면'이 아니면 즉시 무시 (BumpScreen 등이 위에 있을 때 방지)
    if (ModalRoute.of(context)?.isCurrent != true) return;

    // 2. 이미 이동 중이면 무시
    if (_isNavigating) return;

    // 3. 문 잠그기 & 센서 끄기
    setState(() => _isNavigating = true);
    _shakeDetector?.stopListening();

    if (mounted) {
      // 4. 화면 이동 (돌아올 때까지 대기)
      await context.push('/bump');
    }

    // 5. 돌아오면 센서 다시 켜기 & 문 열기
    if (mounted) {
       _shakeDetector?.startListening();
       setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModeIndex = ref.watch(modeProvider);
    final user = FirebaseAuth.instance.currentUser;
    String getModeKey(int index) => ['business', 'social', 'private'][index];

    return Scaffold(
      backgroundColor: Colors.black, 
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? ref.read(databaseServiceProvider).getProfileStream(user.uid)
            : null,
        builder: (context, snapshot) {
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
                'style': currentProfile['style'],
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
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.3,
                    colors: [
                      Color(0xFF1A1A1A), 
                      Colors.black,      
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),

              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'my_card',
                        child: Interactive3DCard(
                          child: BumpCard(
                            modeIndex: currentModeIndex,
                            primaryColor: accentColor,
                            data: cardData,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      
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
                              letterSpacing: 1.0, 
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                top: 60, right: 20,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
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