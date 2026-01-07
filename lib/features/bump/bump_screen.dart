import 'dart:async';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/features/home/home_screen.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slide_to_act/slide_to_act.dart';

class BumpScreen extends ConsumerStatefulWidget {
  const BumpScreen({super.key});

  @override
  ConsumerState<BumpScreen> createState() => _BumpScreenState();
}

class _BumpScreenState extends ConsumerState<BumpScreen> {
  String? _myRequestId;
  Timer? _matchTimer;
  
  @override
  void dispose() {
    _matchTimer?.cancel();
    // [핵심] 화면이 꺼질 때 내 요청을 서버에서 삭제 (Clean Up)
    if (_myRequestId != null) {
      // 비동기 실행을 위해 fire-and-forget 방식으로 호출
      ref.read(databaseServiceProvider).cancelBumpRequest(_myRequestId!);
    }
    super.dispose();
  }

  Future<void> _startBumpProcess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dbService = ref.read(databaseServiceProvider);
    final modeIndex = ref.read(modeProvider);
    final modeKey = ['business', 'social', 'private'][modeIndex];

    try {
      final userData = await dbService.getUserData(user.uid);
      final myProfile = (userData?['profiles'] as Map?)?[modeKey] ?? {'name': 'Unknown'};

      // 요청 생성
      String reqId = await dbService.createBumpRequest(user.uid, myProfile);
      
      if (mounted) {
        setState(() => _myRequestId = reqId);
      }

      // 주기적 매칭 시도
      _matchTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        // 내 요청 ID와 UID를 넘겨서, '내가 아닌 다른 사람'을 찾게 함
        dbService.findAndMatch(reqId, user.uid);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e")));
        // 오류 시 즉시 요청 삭제
        if (_myRequestId != null) {
           dbService.cancelBumpRequest(_myRequestId!);
           setState(() => _myRequestId = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = ref.watch(databaseServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(), // 뒤로가기 누르면 dispose()가 실행됨 -> 자동 삭제
        ),
      ),
      body: _myRequestId == null
          ? _buildSlideToConnect()
          : StreamBuilder<DocumentSnapshot>(
              stream: dbService.getBumpRequestStream(_myRequestId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return _buildSearching();

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) return _buildSearching();

                if (data['status'] == 'matched') {
                  _matchTimer?.cancel(); 
                  
                  final partnerData = data['partnerCardData'] ?? {'name': 'Unknown'};
                  final user = FirebaseAuth.instance.currentUser!;
                  
                  // 중복 저장 방지 로직이 있으면 좋으나, set()은 덮어쓰기이므로 안전
                  dbService.saveConnection(
                    myUid: user.uid, 
                    partnerUid: data['matchedWith'] ?? 'unknown', 
                    partnerData: partnerData
                  );

                  return _buildMatchSuccess(partnerData);
                }

                return _buildSearching();
              },
            ),
    );
  }

  Widget _buildSlideToConnect() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Icon(Icons.phonelink_ring, size: 80, color: Colors.white54),
        const SizedBox(height: 20),
        Text("주변 기기와 연결하려면\n슬라이드 하세요", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SlideAction(
            text: "밀어서 연결하기",
            textStyle: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
            outerColor: Colors.white,
            innerColor: const Color(0xFF4B6EFF),
            sliderButtonIcon: const Icon(Icons.arrow_forward, color: Colors.white),
            onSubmit: () => _startBumpProcess(),
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildSearching() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
          const SizedBox(height: 30),
          Text("주변 사용자를 찾는 중...", style: GoogleFonts.outfit(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 10),
          Text("상대방도 같이 연결 중이어야 해요", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildMatchSuccess(Map<String, dynamic> partnerData) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
          const SizedBox(height: 30),
          Text("${partnerData['name'] ?? '알 수 없음'}님과\n연결되었습니다!", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text("${partnerData['company'] ?? ''} · ${partnerData['role'] ?? ''}", style: GoogleFonts.outfit(color: Colors.grey)),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () { context.pop(); context.push('/history'); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
            child: const Text("명함첩에서 확인하기", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}