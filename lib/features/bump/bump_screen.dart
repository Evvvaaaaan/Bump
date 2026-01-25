// import 'dart:async';
// import 'dart:math';
// import 'package:bump/core/services/database_service.dart';
// import 'package:bump/core/services/shake_detector.dart';
// import 'package:bump/features/bump/widgets/bump_match_dialog.dart'; // [필수] 위 파일 임포트
// import 'package:bump/features/home/home_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // 햅틱용
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:slide_to_act/slide_to_act.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:audioplayers/audioplayers.dart';

// class BumpScreen extends ConsumerStatefulWidget {
//   const BumpScreen({super.key});

//   @override
//   ConsumerState<BumpScreen> createState() => _BumpScreenState();
// }

// class _BumpScreenState extends ConsumerState<BumpScreen> {


//   String? _myRequestId;
//   ShakeDetector? _shakeDetector;
//   bool _isSheetOpen = false; 
//   bool _isProcessing = false; 

//   @override
//   void initState() {
//     super.initState();
//     _shakeDetector = ShakeDetector(
//       shakeThresholdGravity: 1.8,
//       onPhoneShake: () {
//         if (_isProcessing || _myRequestId != null || _isSheetOpen) return;
//         _startBumpProcess(); 
//       },
//     );
//     _shakeDetector?.startListening();
//   }
  
//   @override
//   void dispose() {
//     _shakeDetector?.stopListening();
//     if (_myRequestId != null) {
//       // 화면 나갈 때 요청 취소 (선택 사항)
//       // ref.read(databaseServiceProvider).cancelBumpRequest(_myRequestId!);
//     }
//     super.dispose();
//   }

//   Future<void> _startBumpProcess() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     _shakeDetector?.stopListening();
//     if (mounted) setState(() => _isProcessing = true);

//     final dbService = ref.read(databaseServiceProvider);
//     final modeIndex = ref.read(modeProvider);
//     final modeKey = ['business', 'social', 'private'][modeIndex];

//     try {
//       final userData = await dbService.getUserData(user.uid);
//       final myProfile = (userData?['profiles'] as Map?)?[modeKey] ?? {'name': 'Unknown'};

//       String reqId = await dbService.createBumpRequest(user.uid, myProfile);
      
//       if (mounted) {
//         setState(() {
//           _myRequestId = reqId;
//           _isProcessing = false; 
//         });
//         _showMatchList(reqId);
//       }
//     } catch (e) {
//       _shakeDetector?.startListening();
//       if (mounted) {
//         setState(() => _isProcessing = false);
//         if (_myRequestId != null) {
//            dbService.cancelBumpRequest(_myRequestId!);
//            setState(() => _myRequestId = null);
//         }
//       }
//     }
//   }

//   // [하단 시트] 레이더 화면 표시
//   void _showMatchList(String reqId) {
//     setState(() => _isSheetOpen = true);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true, // 전체 높이 사용 가능하게
//       backgroundColor: Colors.transparent,
//       enableDrag: false, // 레이더 조작 중 닫힘 방지
//       builder: (context) => BumpMatchListSheet(myRequestId: reqId),
//     ).whenComplete(() {
//       // 시트가 닫혔을 때 로직
//       if (mounted) {
//         setState(() {
//           _isSheetOpen = false;
//           _myRequestId = null; // 내 화면에서는 요청 상태 초기화 (새 요청 가능하게)
//         });
        
//         // 센서 재가동
//         _shakeDetector?.startListening();

//         // [핵심 해결책] 
//         // 시트가 닫혀도 즉시 삭제하지 않고 15초 딜레이를 줍니다.
//         // 이렇게 해야 상대방이 아직 연결하지 못했을 때, 나를 계속 볼 수 있습니다.
//         Future.delayed(const Duration(seconds: 15), () {
//           // 15초 뒤에 서버에서 삭제 요청
//           try {
//             print("⏳ 15초 경과: 범프 요청 삭제 실행 ($reqId)");
//             ref.read(databaseServiceProvider).cancelBumpRequest(reqId);
//           } catch (e) {
//             print("범프 요청 삭제 중 오류 (이미 삭제됨 등): $e");
//           }
//         });
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         leading: IconButton(
//           icon: const Icon(Icons.close, color: Colors.white),
//           onPressed: () {
//             if (_myRequestId != null) {
//               ref.read(databaseServiceProvider).cancelBumpRequest(_myRequestId!);
//             }
//             context.pop();
//           },
//         ),
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Spacer(),
//           const Icon(Icons.phonelink_ring, size: 80, color: Colors.white54),
//           const SizedBox(height: 20),
//           Text(
//             "휴대폰을 흔들거나\n슬라이드 하세요", 
//             textAlign: TextAlign.center, 
//             style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)
//           ),
//           const Spacer(),
//           Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: SlideAction(
//               text: "밀어서 연결하기",
//               textStyle: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
//               outerColor: Colors.white,
//               innerColor: const Color(0xFF4B6EFF),
//               sliderButtonIcon: const Icon(Icons.arrow_forward, color: Colors.white),
//               onSubmit: () {
//                  if (!_isProcessing && _myRequestId == null && !_isSheetOpen) {
//                     _startBumpProcess();
//                  }
//                  return null;
//               },
//             ),
//           ),
//           const SizedBox(height: 50),
//         ],
//       ),
//     );
//   }
// }

// // ------------------------------------------------------------------
// // [하단 시트] 레이더 스캔, 거리 필터링, 그리고 BumpMatchDialog 호출
// // ------------------------------------------------------------------
// class BumpMatchListSheet extends ConsumerStatefulWidget { 
//   final String myRequestId; 

//   const BumpMatchListSheet({super.key, required this.myRequestId});

//   @override
//   ConsumerState<BumpMatchListSheet> createState() => _BumpMatchListSheetState();
// }

// class _BumpMatchListSheetState extends ConsumerState<BumpMatchListSheet> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   final Set<String> _selectedIds = {}; 
//   Position? _myPosition; 
//   bool _isLoadingLocation = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 4),
//     )..repeat();
//     _getCurrentLocation();
//   }

//   Future<void> _getCurrentLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       if (mounted) setState(() { _myPosition = position; _isLoadingLocation = false; });
//     } catch (e) {
//       if (mounted) setState(() => _isLoadingLocation = false);
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   // 선택된 사용자들과 실제 연결 수행 (다이얼로그 확인 후 호출됨)
//   Future<void> _executeConnection(List<QueryDocumentSnapshot> allDocs) async {
//     final myUid = FirebaseAuth.instance.currentUser?.uid;
//     if (myUid == null) return;
    
//     final dbService = ref.read(databaseServiceProvider);
//     int successCount = 0;

//     for (var doc in allDocs) {
//       final data = doc.data() as Map<String, dynamic>;
//       final partnerUid = data['requesterUid'];
//       if (_selectedIds.contains(partnerUid)) {
//         try {
//           await dbService.saveContact(
//             myUid: myUid,
//             targetUid: partnerUid,
//             targetProfileData: data['cardData'] ?? {},
//           );
//           successCount++;
//         } catch (e) {
//           debugPrint("저장 실패: $e");
//         }
//       }
//     }

//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("$successCount명과 연결되었습니다! 🎉"), backgroundColor: Colors.green),
//       );
//       Navigator.pop(context); // 시트 닫기
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final myUid = FirebaseAuth.instance.currentUser?.uid;
//     final searchTime = DateTime.now().subtract(const Duration(seconds: 30));

//     return Container(
//       height: 600, 
//       decoration: const BoxDecoration(
//         color: Color(0xFF121212), 
//         borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
//       ),
//       child: Column(
//         children: [
//           // 헤더
//           Padding(
//             padding: const EdgeInsets.all(24),
//             child: Row(
//               children: [
//                 const Icon(Icons.radar, color: Color(0xFF4B6EFF)),
//                 const SizedBox(width: 10),
//                 Text("주변 탐색", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//                 const Spacer(),
//                 IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54)),
//               ],
//             ),
//           ),
          
//           // 레이더
//           Expanded(
//             child: _isLoadingLocation 
//               ? const Center(child: CircularProgressIndicator(color: Colors.white24))
//               : StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance.collection('bump_requests').where('timestamp', isGreaterThan: searchTime).snapshots(),
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white24));

//                     final docs = snapshot.data!.docs.where((doc) {
//                       final data = doc.data() as Map<String, dynamic>;
//                       if (data['requesterUid'] == myUid) return false;
//                       if (data['location'] == null) return false;
//                       GeoPoint targetLoc = data['location'];
//                       double distance = Geolocator.distanceBetween(_myPosition!.latitude, _myPosition!.longitude, targetLoc.latitude, targetLoc.longitude);
//                       return distance <= 100; 
//                     }).toList();

//                     return Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         RotationTransition(
//                           turns: _controller,
//                           child: Container(
//                             margin: const EdgeInsets.all(40),
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               gradient: SweepGradient(center: Alignment.center, colors: [Colors.blue.withOpacity(0.0), Colors.blue.withOpacity(0.15)], stops: const [0.5, 1.0]),
//                             ),
//                           ),
//                         ),
//                         for (int i = 1; i <= 3; i++)
//                           Container(width: 100.0 * i, height: 100.0 * i, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.05)))),
                        
//                         if (docs.isEmpty) Center(child: Text("근처에 발견된 사용자가 없습니다.", style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 13))),

//                         ...List.generate(docs.length, (index) {
//                           final data = docs[index].data() as Map<String, dynamic>;
//                           final uid = data['requesterUid'];
//                           final card = data['cardData'] ?? {};
//                           final GeoPoint targetLoc = data['location'];
//                           double distance = Geolocator.distanceBetween(_myPosition!.latitude, _myPosition!.longitude, targetLoc.latitude, targetLoc.longitude);
//                           final angle = (2 * pi / docs.length) * index - (pi / 2);
//                           final isSelected = _selectedIds.contains(uid);

//                           return Align(
//                             alignment: Alignment(cos(angle) * 0.7, sin(angle) * 0.5),
//                             child: GestureDetector(
//                               onTap: () => setState(() => isSelected ? _selectedIds.remove(uid) : _selectedIds.add(uid)),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Container(
//                                     padding: const EdgeInsets.all(3),
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       border: Border.all(color: isSelected ? const Color(0xFFF2F2F2) : Colors.transparent, width: 2.5),
//                                       boxShadow: isSelected ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 15)] : [],
//                                     ),
//                                     child: CircleAvatar(
//                                       radius: 30,
//                                       backgroundColor: Colors.grey[900],
//                                       backgroundImage: card['photoUrl'] != null ? NetworkImage(card['photoUrl']) : null,
//                                       child: card['photoUrl'] == null ? const Icon(Icons.person, color: Colors.white54) : null,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFF1E1E1E),
//                                       borderRadius: BorderRadius.circular(8),
//                                       border: Border.all(color: Colors.white12),
//                                     ),
//                                     child: Column(
//                                       children: [
//                                         Text(card['name'] ?? 'Unknown', style: GoogleFonts.notoSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
//                                         Text("${distance.toStringAsFixed(0)}m", style: GoogleFonts.outfit(color: const Color(0xFF4B6EFF), fontSize: 10, fontWeight: FontWeight.bold)),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }),
//                       ],
//                     );
//                   },
//                 ),
//           ),

//           // 하단 버튼 (수정됨: 클릭 시 Dialog 띄움)
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 48,
//                 child: ElevatedButton(
//                   onPressed: _selectedIds.isEmpty ? null : () async {
//                     // 1. 현재 화면의 모든 데이터를 다시 가져옴 (간단 처리를 위해)
//                     final searchTime = DateTime.now().subtract(const Duration(seconds: 30));
//                     final snapshot = await FirebaseFirestore.instance
//                         .collection('bump_requests')
//                         .where('timestamp', isGreaterThan: searchTime)
//                         .get();
                    
//                     if (!context.mounted) return;

//                     // 2. 선택된 사용자 중 첫 번째 사용자의 데이터를 찾음 (대표로 보여주기 위함)
//                     // 실제로는 여러 명일 수 있지만, Dialog는 1:1 매칭 느낌을 위해 첫 번째 사람을 보여줍니다.
//                     Map<String, dynamic>? firstPartnerData;
//                     for (var doc in snapshot.docs) {
//                       final data = doc.data();
//                       if (_selectedIds.contains(data['requesterUid'])) {
//                         firstPartnerData = data['cardData'] as Map<String, dynamic>?;
//                         break;
//                       }
//                     }

//                     if (firstPartnerData != null) {
//                       // 3. [핵심] 5초 대기 다이얼로그 띄우기
//                       HapticFeedback.heavyImpact();
//                       showDialog(
//                         context: context,
//                         barrierDismissible: false, // 5초 강제 대기
//                         builder: (context) => BumpMatchDialog(
//                           partnerData: firstPartnerData!,
//                           onConfirm: () {
//                             // 4. 다이얼로그에서 확인 누르면 실제 저장 수행
//                             _executeConnection(snapshot.docs);
//                           },
//                         ),
//                       );
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _selectedIds.isEmpty ? const Color(0xFF222222) : const Color(0xFFF2F2F2),
//                     foregroundColor: _selectedIds.isEmpty ? Colors.white24 : const Color(0xFF1A1A1A),
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: Text(
//                     _selectedIds.isEmpty ? "연결할 상대를 터치하세요" : "${_selectedIds.length}명과 연결하기",
//                     style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart'; // [필수] 오디오
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/shake_detector.dart';
import 'package:bump/features/bump/widgets/bump_match_dialog.dart'; // [필수] 다이얼로그 위젯
import 'package:bump/features/home/home_screen.dart'; // 모드 프로바이더용
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 햅틱용
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'; // 위치용
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
  bool _isSheetOpen = false; 
  bool _isProcessing = false; 

  // [오디오 추가]
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startScanAudio(); // 화면 진입 시 오디오 시작

    _shakeDetector = ShakeDetector(
      shakeThresholdGravity: 1.8,
      onPhoneShake: () {
        if (_isProcessing || _myRequestId != null || _isSheetOpen) return;
        _startBumpProcess(); 
      },
    );
    _shakeDetector?.startListening();
  }
  
  // 오디오 시작 (반복 재생)
  Future<void> _startScanAudio() async {
    try {
      await _audioPlayer.setVolume(0.5);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/radar_scan.mp3')); // 파일 경로 확인
    } catch (e) {
      debugPrint("오디오 오류: $e");
    }
  }

  // 오디오 정지
  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // 오디오 리소스 해제
    _shakeDetector?.stopListening();
    if (_myRequestId != null) {
      // 화면 나갈 때 요청 취소 (안전장치)
       // ref.read(databaseServiceProvider).cancelBumpRequest(_myRequestId!);
    }
    super.dispose();
  }

  Future<void> _startBumpProcess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 햅틱 피드백
    HapticFeedback.heavyImpact();

    _shakeDetector?.stopListening();
    if (mounted) setState(() => _isProcessing = true);

    final dbService = ref.read(databaseServiceProvider);
    final modeIndex = ref.read(modeProvider);
    final modeKey = ['business', 'social', 'private'][modeIndex];

    try {
      final userData = await dbService.getUserData(user.uid);
      final myProfile = (userData?['profiles'] as Map?)?[modeKey] ?? {'name': 'Unknown'};

      // 1. 요청 생성 (위치 정보 포함)
      String reqId = await dbService.createBumpRequest(user.uid, myProfile);
      
      if (mounted) {
        setState(() {
          _myRequestId = reqId;
          _isProcessing = false; 
        });
        _showMatchList(reqId);
      }
    } catch (e) {
      _shakeDetector?.startListening();
      if (mounted) {
        setState(() => _isProcessing = false);
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
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      enableDrag: false, 
      builder: (context) => BumpMatchListSheet(
        myRequestId: reqId,
        onStopAudio: _stopAudio, // 시트에서 매칭 성공 시 소리 끄기 위함
      ),
    ).whenComplete(() {
      // 시트 닫힘 처리
      if (mounted) {
        setState(() {
          _isSheetOpen = false;
          _myRequestId = null; 
        });
        
        // 오디오 다시 켜기 (혹시 안 꺼졌으면) 또는 재진입 시 다시 켜기
        // 여기선 화면이 pop되지 않았다면 다시 켜는게 맞지만, 
        // 보통 매칭 후엔 다른 화면이나 홈으로 갈 것이므로 상황에 따라 다름.
        // 우선은 그냥 둠.

        _shakeDetector?.startListening();

        // [15초 뒤 삭제 로직]
        Future.delayed(const Duration(seconds: 15), () {
          try {
            print("⏳ 15초 경과: 범프 요청 삭제 실행 ($reqId)");
            ref.read(databaseServiceProvider).cancelBumpRequest(reqId);
          } catch (e) {
            print("삭제 오류: $e");
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            context.pop(); // 오디오 dispose됨
          },
        ),
      ),
      body: Column(
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
                 return null;
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// [하단 시트] 레이더 스캔
// ------------------------------------------------------------------
class BumpMatchListSheet extends ConsumerStatefulWidget { 
  final String myRequestId;
  final VoidCallback onStopAudio; // 오디오 정지 콜백

  const BumpMatchListSheet({
    super.key, 
    required this.myRequestId,
    required this.onStopAudio,
  });

  @override
  ConsumerState<BumpMatchListSheet> createState() => _BumpMatchListSheetState();
}

class _BumpMatchListSheetState extends ConsumerState<BumpMatchListSheet> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Set<String> _selectedIds = {}; 
  Position? _myPosition; 
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() { _myPosition = position; _isLoadingLocation = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 실제 연결 수행
  Future<void> _executeConnection(List<QueryDocumentSnapshot> allDocs) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    
    final dbService = ref.read(databaseServiceProvider);
    int successCount = 0;

    for (var doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final partnerUid = data['requesterUid'];
      if (_selectedIds.contains(partnerUid)) {
        try {
          await dbService.saveContact(
            myUid: myUid,
            targetUid: partnerUid,
            targetProfileData: data['cardData'] ?? {},
          );
          successCount++;
        } catch (e) {
          debugPrint("저장 실패: $e");
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$successCount명과 연결되었습니다! 🎉"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // 시트 닫기 -> BumpScreen 복귀
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    // 30초 이내 요청만
    final searchTime = DateTime.now().subtract(const Duration(seconds: 30));

    return Container(
      height: 600, 
      decoration: const BoxDecoration(
        color: Color(0xFF121212), 
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.radar, color: Color(0xFF4B6EFF)),
                const SizedBox(width: 10),
                Text("주변 탐색", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54)),
              ],
            ),
          ),
          
          // 레이더
          Expanded(
            child: _isLoadingLocation 
              ? const Center(child: CircularProgressIndicator(color: Colors.white24))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('bump_requests').where('timestamp', isGreaterThan: searchTime).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white24));

                    final docs = snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['requesterUid'] == myUid) return false;
                      if (data['location'] == null) return false;
                      // 거리 계산 (100m 이내)
                      GeoPoint targetLoc = data['location'];
                      double distance = Geolocator.distanceBetween(_myPosition!.latitude, _myPosition!.longitude, targetLoc.latitude, targetLoc.longitude);
                      return distance <= 100; 
                    }).toList();

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // 레이더 애니메이션
                        RotationTransition(
                          turns: _controller,
                          child: Container(
                            margin: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(center: Alignment.center, colors: [Colors.blue.withOpacity(0.0), Colors.blue.withOpacity(0.15)], stops: const [0.5, 1.0]),
                            ),
                          ),
                        ),
                        // 원형 가이드
                        for (int i = 1; i <= 3; i++)
                          Container(width: 100.0 * i, height: 100.0 * i, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.05)))),
                        
                        if (docs.isEmpty) Center(child: Text("근처에 발견된 사용자가 없습니다.", style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 13))),

                        // 발견된 사용자 점들
                        ...List.generate(docs.length, (index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final uid = data['requesterUid'];
                          final card = data['cardData'] ?? {};
                          final GeoPoint targetLoc = data['location'];
                          double distance = Geolocator.distanceBetween(_myPosition!.latitude, _myPosition!.longitude, targetLoc.latitude, targetLoc.longitude);
                          
                          // 각도 분산
                          final angle = (2 * pi / docs.length) * index - (pi / 2);
                          final isSelected = _selectedIds.contains(uid);

                          return Align(
                            alignment: Alignment(cos(angle) * 0.7, sin(angle) * 0.5),
                            child: GestureDetector(
                              onTap: () => setState(() => isSelected ? _selectedIds.remove(uid) : _selectedIds.add(uid)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 프로필 아이콘
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isSelected ? const Color(0xFFF2F2F2) : Colors.transparent, width: 2.5),
                                      boxShadow: isSelected ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 15)] : [],
                                    ),
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.grey[900],
                                      backgroundImage: card['photoUrl'] != null ? NetworkImage(card['photoUrl']) : null,
                                      child: card['photoUrl'] == null ? const Icon(Icons.person, color: Colors.white54) : null,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // 이름 태그
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(card['name'] ?? 'Unknown', style: GoogleFonts.notoSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                        Text("${distance.toStringAsFixed(0)}m", style: GoogleFonts.outfit(color: const Color(0xFF4B6EFF), fontSize: 10, fontWeight: FontWeight.bold)),
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

          // 하단 연결 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedIds.isEmpty ? null : () async {
                    // 매칭 시도 시 오디오 정지
                    widget.onStopAudio(); 

                    // 1. 현재 화면의 모든 데이터를 다시 가져옴 (간단 처리를 위해)
                    final searchTime = DateTime.now().subtract(const Duration(seconds: 30));
                    final snapshot = await FirebaseFirestore.instance
                        .collection('bump_requests')
                        .where('timestamp', isGreaterThan: searchTime)
                        .get();
                    
                    if (!context.mounted) return;

                    // 2. 선택된 사용자 중 첫 번째 사용자의 데이터 찾기
                    Map<String, dynamic>? firstPartnerData;
                    for (var doc in snapshot.docs) {
                      final data = doc.data();
                      if (_selectedIds.contains(data['requesterUid'])) {
                        firstPartnerData = data['cardData'] as Map<String, dynamic>?;
                        // 선택된 사람에게 modeIndex 정보가 없다면 기본값 0(Business) 부여
                        if (firstPartnerData != null && !firstPartnerData.containsKey('modeIndex')) {
                           firstPartnerData['modeIndex'] = 0; 
                        }
                        break;
                      }
                    }

                    if (firstPartnerData != null) {
                      // 3. [핵심] 5초 대기 다이얼로그 띄우기
                      HapticFeedback.heavyImpact();
                      showDialog(
                        context: context,
                        barrierDismissible: false, // 5초 강제 대기
                        builder: (context) => BumpMatchDialog(
                          partnerData: firstPartnerData!,
                          onConfirm: () {
                            // 4. 다이얼로그 확인 후 저장 수행
                            _executeConnection(snapshot.docs);
                          },
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedIds.isEmpty ? const Color(0xFF222222) : const Color(0xFFF2F2F2),
                    foregroundColor: _selectedIds.isEmpty ? Colors.white24 : const Color(0xFF1A1A1A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _selectedIds.isEmpty ? "연결할 상대를 터치하세요" : "${_selectedIds.length}명과 연결하기",
                    style: GoogleFonts.notoSans(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2),
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