// (Imports 생략 - 기존과 동일)
import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/shake_detector.dart';
import 'package:bump/features/home/widgets/bump_card.dart';
import 'package:bump/features/home/widgets/mode_switcher.dart';
import 'package:bump/features/home/widgets/parallax_background.dart';
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? ref.read(databaseServiceProvider).getProfileStream(user.uid)
            : null,
        builder: (context, snapshot) {
          Color primary = AppColors.businessPrimary;
          Color accent = AppColors.businessAccent;

          if (currentModeIndex == 1) { 
            primary = AppColors.socialPrimary; 
            accent = AppColors.socialAccent; 
          } else if (currentModeIndex == 2) { 
            primary = AppColors.privatePrimary; 
            accent = AppColors.privateAccent; 
          }

          Map<String, dynamic> cardData = {};

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final profiles = data['profiles'] as Map<String, dynamic>?;
            final currentProfile = profiles?[getModeKey(currentModeIndex)];
            
            if (currentProfile != null) {
              cardData = {
                'name': currentProfile['name'],
                'photoUrl': currentProfile['photoUrl'],
                // 모드별 필드
                'role': currentProfile['role'],
                'company': currentProfile['company'],
                'phone': currentProfile['phone'],
                
                'bio': currentProfile['bio'],
                'location': currentProfile['location'],
                'email': currentProfile['email'],
                'instagram': currentProfile['instagram'],
                
                // [New] Social Fields
                'mbti': currentProfile['mbti'],
                'music': currentProfile['music'],
                'birthday': currentProfile['birthday'],
                'hobbies': currentProfile['hobbies'],
              };
            }
          }

          return Stack(
            children: [
              ParallaxBackground(primaryColor: primary, accentColor: accent),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BumpCard(
                        modeIndex: currentModeIndex,
                        primaryColor: accent,
                        data: cardData,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "폰을 흔들어 교환하세요",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
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
                top: 50, right: 20,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
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