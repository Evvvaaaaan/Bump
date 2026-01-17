import 'dart:async';
import 'dart:math'; // 레이더 UI 수학 계산용
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/shake_detector.dart'; // [필수] ShakeDetector 파일 필요
import 'package:bump/features/home/home_screen.dart'; // modeProvider 가져오기 위해 필요
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:geolocator/geolocator.dart'; // [필수] 위치 계산용

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
      shakeThresholdGravity: 1.8, // 감도 (낮을수록 민감)
      onPhoneShake: () {
        // 처리 중이거나, 이미 요청 중이거나, 시트가 열려있으면 무시
        if (_isProcessing || _myRequestId != null || _isSheetOpen) {
          return; 
        }
        _startBumpProcess(); 
      },
    );
    _shakeDetector?.startListening();
  }
  
  @override
  void dispose() {
    _shakeDetector?.stopListening();
    // 화면을 나갈 때 요청이 남아있다면 취소 (선택 사항)
    if (_myRequestId != null) {
      // ref.read(databaseServiceProvider).cancelBumpRequest(_myRequestId!);
    }
    super.dispose();
  }

  // [프로세스 시작] 흔들거나 슬라이드 했을 때
  Future<void> _startBumpProcess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 중복 실행 방지를 위해 센서 일시 정지
    _shakeDetector?.stopListening();
    if (mounted) setState(() => _isProcessing = true);

    final dbService = ref.read(databaseServiceProvider);
    
    // 현재 선택된 모드(Business/Social/Private) 가져오기
    final modeIndex = ref.read(modeProvider);
    final modeKey = ['business', 'social', 'private'][modeIndex];

    try {
      final userData = await dbService.getUserData(user.uid);
      final myProfile = (userData?['profiles'] as Map?)?[modeKey] ?? {'name': 'Unknown'};

      // 2. 서버에 요청 생성 (DatabaseService 내부에서 위치 정보 저장함)
      String reqId = await dbService.createBumpRequest(user.uid, myProfile);
      
      if (mounted) {
        setState(() {
          _myRequestId = reqId;
          _isProcessing = false; 
        });
        
        // 3. 레이더 시트 띄우기
        _showMatchList(reqId);
      }
    } catch (e) {
      // 실패 시 다시 감지 시작
      _shakeDetector?.startListening();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e")));
        setState(() => _isProcessing = false);
        
        // 혹시 생성된 ID가 있다면 삭제
        if (_myRequestId != null) {
           dbService.cancelBumpRequest(_myRequestId!);
           setState(() => _myRequestId = null);
        }
      }
    }
  }

  // [하단 시트] 레이더 화면 표시
  void _showMatchList(String reqId) {
    setState(() => _isSheetOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 전체 높이 사용 가능하게
      backgroundColor: Colors.transparent,
      enableDrag: false, // 레이더 조작 중 닫힘 방지
      builder: (context) => BumpMatchListSheet(myRequestId: reqId),
    ).whenComplete(() {
      // 시트가 닫혔을 때 로직
      if (mounted) {
        setState(() {
          _isSheetOpen = false;
          _myRequestId = null; // 요청 초기화
        });
        
        // 시트 닫으면 서버에서 내 요청 삭제 (청소)
        ref.read(databaseServiceProvider).cancelBumpRequest(reqId);

        // 다시 흔들 수 있게 센서 재가동
        _shakeDetector?.startListening();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 밖에서는 단순히 대기 화면만 보여줌 (실제 로직은 BottomSheet에서 수행)
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            if (_myRequestId != null) {
              ref.read(databaseServiceProvider).cancelBumpRequest(_myRequestId!);
            }
            context.pop();
          },
        ),
      ),
      body: _buildSlideToConnect(),
    );
  }

  Widget _buildSlideToConnect() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Icon(Icons.phonelink_ring, size: 80, color: Colors.white54),
        const SizedBox(height: 20),
        Text(
          "휴대폰을 흔들거나\n슬라이드 하세요", 
          textAlign: TextAlign.center, 
          style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
        ),
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
               if (!_isProcessing && _myRequestId == null && !_isSheetOpen) {
                  _startBumpProcess();
               }
               return null; // SlideAction의 리턴값 처리
            },
          ),
        ),
        const SizedBox(height: 50),
      ],
    );
  }
}

// ------------------------------------------------------------------
// [하단 시트 위젯] 레이더 스캔 및 거리 필터링 (핵심 로직 포함)
// ------------------------------------------------------------------
class BumpMatchListSheet extends ConsumerStatefulWidget { 
  final String myRequestId; 

  const BumpMatchListSheet({super.key, required this.myRequestId});

  @override
  ConsumerState<BumpMatchListSheet> createState() => _BumpMatchListSheetState();
}

class _BumpMatchListSheetState extends ConsumerState<BumpMatchListSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Set<String> _selectedIds = {}; // 다중 선택된 상대방 UID들
  Position? _myPosition; // 내 현재 위치
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    // 1. 레이더 회전 애니메이션 설정
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 2. 내 위치 가져오기 (고정확도)
    _getCurrentLocation();
  }

  // [중요] 내 위치를 가져오는 함수
  Future<void> _getCurrentLocation() async {
    try {
      // 정확도를 높여서(High) 현재 위치를 새로 받아옵니다.
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _myPosition = position;
          _isLoadingLocation = false;
        });
        print("📍 내 위치 확보: ${position.latitude}, ${position.longitude}");
      }
    } catch (e) {
      print("❌ 위치 오류: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // [기능] 선택된 사용자 일괄 저장
  Future<void> _connectSelectedUsers(List<QueryDocumentSnapshot> allDocs) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final dbService = ref.read(databaseServiceProvider);
    int successCount = 0;

    for (var doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final partnerUid = data['requesterUid'];

      // 선택된 사람만 처리
      if (_selectedIds.contains(partnerUid)) {
        try {
          // 명함 저장 (교체 방식)
          await dbService.saveContact(
            myUid: myUid,
            targetUid: partnerUid,
            targetProfileData: data['cardData'] ?? {},
          );
          successCount++;
        } catch (e) {
          print("저장 실패: $e");
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$successCount명과 연결되었습니다! 🎉"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // 완료 후 시트 닫기
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    
    // 최근 30초 이내에 생성된 요청만 검색
    final searchTime = DateTime.now().subtract(const Duration(seconds: 30));

    return Container(
      height: 600, // 레이더 화면 높이
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // 배경색
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // 1. 헤더 영역
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.radar, color: Colors.blueAccent),
                const SizedBox(width: 10),
                const Text("주변 탐색", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54)
                ),
              ],
            ),
          ),
          
          // 2. 메인 레이더 및 사용자 표시 영역
          Expanded(
            child: _isLoadingLocation 
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("GPS 위치 확인 중...", style: TextStyle(color: Colors.white54))
                  ],
                ))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bump_requests')
                      .where('timestamp', isGreaterThan: searchTime) 
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white24));

                    // ===============================================
                    // [핵심 로직] 거리 기반 필터링 (100m 이내만)
                    // ===============================================
                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      
                      // 1. 나 자신은 제외
                      if (data['requesterUid'] == myUid) return false;
                      
                      // 2. 위치 정보가 없으면 제외
                      if (data['location'] == null) return false;

                      // 3. 거리 계산 (단위: 미터)
                      GeoPoint targetLoc = data['location'];
                      double distance = Geolocator.distanceBetween(
                        _myPosition!.latitude, 
                        _myPosition!.longitude, 
                        targetLoc.latitude, 
                        targetLoc.longitude
                      );

                      // [디버깅용 로그]
                      // print("거리 계산: ${data['requesterUid']} -> $distance미터");

                      // 4. 100미터 이내인 사람만 표시
                      return distance <= 100; 
                    }).toList();

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // A. 레이더 배경 애니메이션
                        RotationTransition(
                          turns: _controller,
                          child: Container(
                            margin: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                center: Alignment.center,
                                colors: [Colors.blue.withOpacity(0.0), Colors.blue.withOpacity(0.2)],
                                stops: const [0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // B. 동심원 장식
                        for (int i = 1; i <= 3; i++)
                          Container(
                            width: 100.0 * i,
                            height: 100.0 * i,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
                            ),
                          ),
                        
                        // C. 결과 없음 메시지
                        if (docs.isEmpty)
                          const Center(child: Text("근처(100m)에 사용자가 없습니다.", style: TextStyle(color: Colors.white38))),

                        // D. 사용자 아이콘 배치 (원형으로 퍼뜨리기)
                        ...List.generate(docs.length, (index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final uid = data['requesterUid'];
                          final card = data['cardData'] ?? {};
                          final GeoPoint targetLoc = data['location'];
                          
                          // 거리 UI 표시용 재계산
                          double distance = Geolocator.distanceBetween(
                            _myPosition!.latitude, _myPosition!.longitude, 
                            targetLoc.latitude, targetLoc.longitude
                          );

                          // 원형 배치 각도 계산
                          final angle = (2 * pi / docs.length) * index - (pi / 2);
                          final isSelected = _selectedIds.contains(uid);

                          return Align(
                            alignment: Alignment(cos(angle) * 0.7, sin(angle) * 0.5), // 타원형 배치
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSelected ? _selectedIds.remove(uid) : _selectedIds.add(uid);
                                });
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 프로필 아바타
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      // 선택 시 파란색 테두리
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF4B6EFF) : Colors.transparent,
                                        width: 3
                                      ),
                                      boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 15)] : [],
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundImage: card['photoUrl'] != null ? NetworkImage(card['photoUrl']) : null,
                                      child: card['photoUrl'] == null ? const Icon(Icons.person) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // 이름표 및 거리 표시
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(card['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        // [거리 표시]
                                        Text(
                                          "${distance.toStringAsFixed(0)}m", 
                                          style: const TextStyle(color: Colors.greenAccent, fontSize: 10)
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
          ),

          // 3. 하단 연결 버튼 (선택된 사람이 있을 때 활성화)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedIds.isEmpty ? null : () async {
                    // 선택된 사용자들과 연결 시도
                    // 간편 처리를 위해 스냅샷을 한 번 더 조회 (실제로는 상태 관리로 최적화 가능)
                    final searchTime = DateTime.now().subtract(const Duration(seconds: 30));
                    final snapshot = await FirebaseFirestore.instance
                        .collection('bump_requests')
                        .where('timestamp', isGreaterThan: searchTime)
                        .get();
                    
                    if (context.mounted) {
                      _connectSelectedUsers(snapshot.docs);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedIds.isEmpty ? Colors.grey[900] : const Color(0xFF4B6EFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: _selectedIds.isEmpty ? 0 : 5,
                  ),
                  child: Text(
                    _selectedIds.isEmpty 
                      ? "연결할 상대를 터치하세요" 
                      : "${_selectedIds.length}명과 명함 교환하기",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}