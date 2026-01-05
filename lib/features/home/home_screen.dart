import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/shake_detector.dart';
import 'package:bump/features/home/widgets/mode_switcher.dart';
import 'package:bump/features/home/widgets/parallax_background.dart';
import 'package:bump/features/home/widgets/pulse_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// State for current mode: 0=Business, 1=Social, 2=Private
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
    _shakeDetector = ShakeDetector(
      onPhoneShake: () {
        context.push('/bump');
      },
    );
    _shakeDetector?.startListening();
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMode = ref.watch(modeProvider);

    Color getPrimaryColor(int mode) {
      switch (mode) {
        case 0: return AppColors.businessPrimary;
        case 1: return AppColors.socialPrimary;
        case 2: return AppColors.privatePrimary;
        default: return AppColors.businessPrimary;
      }
    }

    Color getAccentColor(int mode) {
      switch (mode) {
        case 0: return AppColors.businessAccent;
        case 1: return AppColors.socialAccent;
        case 2: return AppColors.privateAccent;
        default: return AppColors.businessAccent;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Live Parallax Background
          ParallaxBackground(
            primaryColor: getPrimaryColor(currentMode),
            accentColor: getAccentColor(currentMode),
          ),

          // 2. Center: Pulse Avatar (The Core)
          Center(
            child: PulseAvatar(
              accentColor: getAccentColor(currentMode),
              onTap: () {
                context.push('/bump');
              },
            ),
          ),

          // 3. Bottom: Mode Switcher
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: ModeSwitcher(
              currentMode: currentMode,
              onModeChanged: (index) {
                ref.read(modeProvider.notifier).state = index;
              },
            ),
          ),
          
          // 4. Top Controls
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () => context.push('/history'),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () => context.push('/profile'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => context.push('/editor'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
