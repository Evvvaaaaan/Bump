import 'dart:async';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/shake_detector.dart'; // [필수] ShakeDetector가 있어야 합니다
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
  ShakeDetector? _shakeDetector;
  
  // 상태 관리를 위한 플래그
  bool _isSheetOpen = false; 
  bool _isProcessing = false; 

  @override
  void initState() {
    super.initState();
    // 1. 화면 진입 시 흔들기 감지 시작
    _shakeDetector = ShakeDetector(
      shakeThresholdGravity: 1.8, // 감도 조절 (낮을수록 민감, 기본값 2.7)
      onPhoneShake: () {
        // 이중 안전장치: 처리 중이거나 요청이 있거나 시트가 열려있으면 무시
        if (_isProcessing || _myRequestId != null || _isSheetOpen) {
          return; 
        }

        // 흔들림 감지 즉시 처리 시작
        _startBumpProcess(); 
      },
    );
    _shakeDetector?.startListening();
  }
  
  @override
  void dispose() {
    _shakeDetector?.stopListening(); // 감지 종료
    // 화면이 꺼질 때 내 요청이 남아있다면 삭제 (Clean Up)
    if (_myRequestId != null) {
      ref.read(databaseServiceProvider).cancelBumpRequest(_myRequestId!);
    }
    super.dispose();
  }

  Future<void> _startBumpProcess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // [핵심] 프로세스 시작 즉시 센서 끄기 (중복 실행 원천 차단)
    _shakeDetector?.stopListening();

    if (mounted) setState(() => _isProcessing = true);

    final dbService = ref.read(databaseServiceProvider);
    final modeIndex = ref.read(modeProvider);
    final modeKey = ['business', 'social', 'private'][modeIndex];

    try {
      final userData = await dbService.getUserData(user.uid);
      final myProfile = (userData?['profiles'] as Map?)?[modeKey] ?? {'name': 'Unknown'};

      // 서버에 요청 생성 (비동기 대기)
      String reqId = await dbService.createBumpRequest(user.uid, myProfile);
      
      if (mounted) {
        setState(() {
          _myRequestId = reqId;
          _isProcessing = false; 
        });
        
        // 목록 시트 띄우기
        _showMatchList(reqId);
      }
    } catch (e) {
      // 실패 시 다시 감지 시작
      _shakeDetector?.startListening();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e")));
        setState(() => _isProcessing = false);
        
        if (_myRequestId != null) {
           dbService.cancelBumpRequest(_myRequestId!);
           setState(() => _myRequestId = null);
        }
      }
    }
  }

  void _showMatchList(String reqId) {
    setState(() => _isSheetOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true, // 드래그로 닫기 허용
      builder: (context) => BumpMatchListSheet(myRequestId: reqId),
    ).whenComplete(() {
      // 시트가 닫혔을 때 처리
      if (mounted) {
        setState(() => _isSheetOpen = false);

        // 매칭이 안 된 상태로 닫았다면(취소), 다시 흔들 수 있게 센서 켜기
        if (_myRequestId != null) {
           // (선택사항) 창을 닫으면 요청을 취소하고 초기화하려면 아래 주석 해제
           /*
           ref.read(databaseServiceProvider).cancelBumpRequest(_myRequestId!);
           setState(() => _myRequestId = null);
           _shakeDetector?.startListening(); 
           */
           
           // 현재 로직: 창을 닫아도 요청은 유지됨 (_buildSearching 상태)
           // 요청을 유지할 거라면 센서는 켜지 않음 (중복 요청 방지)
           // 만약 "창 닫음 = 처음으로"가 되길 원하면 위 주석 코드를 쓰세요.
        } else {
           // 이미 _myRequestId가 null이면(초기화된 상태) 센서 재가동
           _shakeDetector?.startListening();
        }
      }
    });
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
          onPressed: () => context.pop(),
        ),
      ),
      body: _myRequestId == null
          ? _buildSlideToConnect()
          : StreamBuilder<DocumentSnapshot>(
              stream: dbService.getBumpRequestStream(_myRequestId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                   // 데이터가 사라졌으면 초기화
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                     if (mounted && _myRequestId != null) {
                       setState(() => _myRequestId = null);
                       _shakeDetector?.startListening(); // 다시 감지 시작
                     }
                   });
                   return _buildSlideToConnect(); 
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null) return _buildSearching();

                // [매칭 성공 감지]
                if (data['status'] == 'matched') {
                  // 시트가 열려있다면 닫기
                  if (_isSheetOpen && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  // 성공 화면에서는 센서를 켜지 않음 (불필요)

                  final partnerData = data['partnerCardData'] ?? {'name': 'Unknown'};
                  final user = FirebaseAuth.instance.currentUser!;
                  
                  // 내 명함첩에 저장
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
        Text("휴대폰을 흔들거나\n슬라이드 하세요", textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SlideAction(
            text: "밀어서 연결하기",
            textStyle: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
            outerColor: Colors.white,
            innerColor: const Color(0xFF4B6EFF),
            sliderButtonIcon: const Icon(Icons.arrow_forward, color: Colors.white),
            onSubmit: () {
               // 슬라이드 버튼 실행 시에도 중복 체크
               if (!_isProcessing && _myRequestId == null && !_isSheetOpen) {
                  _startBumpProcess();
               }
            },
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
          Text("목록에서 상대를 선택해주세요", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white38)),
          const SizedBox(height: 30),
          // 혹시 목록을 닫았을 때 다시 여는 버튼
          TextButton.icon(
            onPressed: () {
              if (_myRequestId != null) _showMatchList(_myRequestId!);
            },
            icon: const Icon(Icons.list, color: Colors.white),
            label: const Text("목록 다시 보기", style: TextStyle(color: Colors.white)),
          )
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

// ------------------------------------------------------------------
// [하단 시트 위젯] 주변 사용자 목록
// ------------------------------------------------------------------
class BumpMatchListSheet extends StatelessWidget {
  final String myRequestId; 

  const BumpMatchListSheet({super.key, required this.myRequestId});

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    
    // 검색 기준: 현재 시간보다 15초 전부터 생성된 요청만 검색
    final searchTime = DateTime.now().subtract(const Duration(seconds: 15));

    return Container(
      height: 500,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("주변 사용자 발견!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          const Text("연결할 상대를 선택해주세요.", style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bump_requests')
                  .where('timestamp', isGreaterThan: searchTime) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("오류가 발생했습니다.", style: const TextStyle(color: Colors.white)));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));

                // [수정] requesterUid로 필터링하여 나를 제외
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['requesterUid'] != myUid; 
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 50, color: Colors.white24),
                        SizedBox(height: 15),
                        Text("주변에 흔든 사람이 없어요.\n친구와 동시에 흔들어보세요!", textAlign: TextAlign.center, style: TextStyle(color: Colors.white30)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    // [수정] 상대방 UID 가져오기 (requesterUid 사용)
                    final partnerUid = data['requesterUid'];
                    
                    final cardData = data['cardData'] ?? {};
                    final name = cardData['name'] ?? '알 수 없음';
                    final role = cardData['role'] ?? '정보 없음';
                    final photoUrl = cardData['photoURL'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                          child: (photoUrl.isEmpty) ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(role, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () async {
                            // [연결] 내 요청 상태를 matched로 변경 -> StreamBuilder가 감지하여 성공 화면으로 전환
                            await FirebaseFirestore.instance.collection('bump_requests').doc(myRequestId).update({
                              'status': 'matched',
                              'matchedWith': partnerUid,
                              'partnerCardData': cardData, 
                            });
                            
                            if (context.mounted) {
                              context.pop(); // 리스트 닫기
                            }
                          },
                          child: const Text("연결", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}