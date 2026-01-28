import 'package:bump/core/services/shake_detector.dart';
import 'package:bump/features/bump/bump_screen.dart';
import 'package:bump/features/editor/card_editor_screen.dart'; 
import 'package:bump/features/design/card_design_screen.dart'; // (경로 확인 필요: features/editor/screens/card_design_screen.dart 일 수도 있음)
import 'package:bump/core/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:bump/features/common/scale_button.dart';
import 'package:bump/features/settings/settings_provider.dart';
// [핵심 수정] 개별 디자인 위젯 대신 통합 렌더러 임포트
import 'package:bump/features/common/card_renderer.dart'; 

// [상태 관리] 현재 선택된 모드 (0: Business, 1: Social, 2: Private)
final modeProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ShakeDetector? _shakeDetector;
  bool _isNavigating = false; 

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

  Future<void> _handleHomeShake() async {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    if (_isNavigating) return;
    final isHapticOn = ref.read(settingsProvider).isHapticEnabled;

    if (isHapticOn == true) {
      print("📳 [DEBUG] 진동을 실행합니다 (Bzzzt!)");
      // await HapticFeedback.heavyImpact();
    } else {
      print("🔕 [DEBUG] 설정이 꺼져있어 진동을 스킵합니다.");
    }
    setState(() => _isNavigating = true);
    _shakeDetector?.stopListening();

    if (mounted) await context.push('/bump');

    if (mounted) {
       _shakeDetector?.startListening();
       setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentModeIndex = ref.watch(modeProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("BUMP", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2)), 
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.notifications_none, color: Colors.white),
          //   onPressed: () {},
          // ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              _buildModeTabs(ref, currentModeIndex),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      
      body: Column(
        children: [
          const Spacer(), 
          
          // 1. 명함 섹션
          _buildCardSection(context, ref, user?.uid, currentModeIndex),
          
          const Spacer(),
        ],
      ),
      
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 1) context.push('/history'); 
          if (index == 2) _handleHomeShake();       
          if (index == 3) context.push('/settings');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined, size: 28), label: 'Contacts'),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF4B6EFF),
              child: Icon(Icons.sensors, color: Colors.white, size: 28),
            ), 
            label: 'Bump'
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 28), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildModeTabs(WidgetRef ref, int currentIndex) {
    final modes = ['Business', 'Social', 'Private'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final isSelected = index == currentIndex;
          return ScaleButton(
            onTap: () => ref.read(modeProvider.notifier).state = index,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  modes[index],
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                if (isSelected)
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardSection(BuildContext context, WidgetRef ref, String? uid, int modeIndex) {
    if (uid == null) return const Text("로그인이 필요합니다", style: TextStyle(color: Colors.white));

    final dbService = ref.watch(databaseServiceProvider);
    final modeKey = ['business', 'social', 'private'][modeIndex];

    return StreamBuilder<DocumentSnapshot>(
      stream: dbService.getProfileStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white24));

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        // 프로필 데이터 가져오기 (없으면 빈 맵)
        final profile = userData?['profiles']?[modeKey] as Map<String, dynamic>? ?? {};
        
        // [핵심 로직 수정] 
        // 1. 기존의 긴 switch 문을 제거했습니다.
        // 2. CardRenderer에 전달하기 위해 modeIndex 정보를 데이터에 포함시킵니다.
        final renderData = Map<String, dynamic>.from(profile);
        renderData['modeIndex'] = modeIndex;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              // [중요] CardRenderer가 templateId를 자동으로 확인하고
              // Glass, Aurora, Neo Brutalism 등 모든 디자인을 알아서 그려줍니다.
              child: CardRenderer(
                data: renderData,
                modeIndex: modeIndex,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSimpleButton(
                  context, 
                  icon: Icons.edit_note, 
                  label: "정보 수정",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CardEditorScreen())),
                ),
                const SizedBox(width: 20),
                _buildSimpleButton(
                  context, 
                  icon: Icons.palette_outlined, 
                  label: "디자인 변경",
                  // CardDesignScreen 경로가 맞는지 확인 필요 (features/editor/screens/card_design_screen.dart 라면 임포트 수정)
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardDesignScreen(modeIndex: modeIndex))),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}