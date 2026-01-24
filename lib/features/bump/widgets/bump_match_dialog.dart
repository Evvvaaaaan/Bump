// import 'dart:async';
// import 'package:bump/features/common/card_renderer.dart'; // [필수] 카드 렌더러 경로 확인
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class BumpMatchDialog extends StatefulWidget {
//   final Map<String, dynamic> partnerData; // 화면에 보여줄 대표 상대방 데이터
//   final VoidCallback onConfirm; // 5초 후 또는 버튼 클릭 시 실행할 저장 함수

//   const BumpMatchDialog({
//     super.key,
//     required this.partnerData,
//     required this.onConfirm,
//   });

//   @override
//   State<BumpMatchDialog> createState() => _BumpMatchDialogState();
// }

// class _BumpMatchDialogState extends State<BumpMatchDialog> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   int _secondsRemaining = 5; // 5초 카운트다운
//   Timer? _timer;

//   @override
//   void initState() {
//     super.initState();
    
//     // 5초 진행바 애니메이션
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 5),
//     )..reverse(from: 1.0);

//     // 1초마다 카운트다운
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() {
//           if (_secondsRemaining > 0) {
//             _secondsRemaining--;
//           } else {
//             _timer?.cancel();
//             _finalize(); // 시간 종료 시 자동 저장
//           }
//         });
//       }
//     });
//   }

//   void _finalize() {
//     if (mounted) {
//       widget.onConfirm(); // 저장 로직 실행
//       Navigator.of(context).pop(); // 창 닫기
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final data = widget.partnerData;
//     final int modeIndex = int.tryParse(data['modeIndex']?.toString() ?? '0') ?? 0;

//     return Dialog(
//       backgroundColor: Colors.transparent,
//       insetPadding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1E1E1E),
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(color: Colors.white10),
//           boxShadow: [
//             BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
//           ],
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "BUMP MATCHED!",
//               style: GoogleFonts.outfit(
//                 color: const Color(0xFF4B6EFF),
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 1.5,
//               ),
//             ),
//             const SizedBox(height: 24),

//             // 상대방 명함 미리보기
//             SizedBox(
//               height: 200,
//               child: CardRenderer(
//                 data: data,
//                 modeIndex: modeIndex,
//               ),
//             ),
            
//             const SizedBox(height: 30),

//             // 타이머 UI
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text("명함첩에 저장하는 중...", style: TextStyle(color: Colors.white54, fontSize: 13)),
//                 Text("$_secondsRemaining초", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//               ],
//             ),
//             const SizedBox(height: 10),
            
//             AnimatedBuilder(
//               animation: _controller,
//               builder: (context, child) {
//                 return ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: LinearProgressIndicator(
//                     value: _controller.value,
//                     backgroundColor: Colors.white10,
//                     color: const Color(0xFF4B6EFF),
//                     minHeight: 6,
//                   ),
//                 );
//               },
//             ),
            
//             const SizedBox(height: 30),

//             // [수정된 버튼 디자인 적용]
//             SizedBox(
//               width: double.infinity,
//               height: 48, // 높이 48px
//               child: ElevatedButton(
//                 onPressed: _finalize,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFF2F2F2), // 오프화이트
//                   foregroundColor: const Color(0xFF1A1A1A), // 진한 검정
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12), // 둥근 모서리 12px
//                   ),
//                 ),
//                 child: Text(
//                   "지금 바로 저장",
//                   style: GoogleFonts.notoSans(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: -0.2,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:bump/features/common/card_renderer.dart'; 
import 'package:bump/features/editor/widgets/dark_geometric_card.dart'; // 디자인별 임포트 (필요 시)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BumpMatchDialog extends StatefulWidget {
  final Map<String, dynamic> partnerData; 
  final VoidCallback onConfirm; 

  const BumpMatchDialog({
    super.key,
    required this.partnerData,
    required this.onConfirm,
  });

  @override
  State<BumpMatchDialog> createState() => _BumpMatchDialogState();
}

class _BumpMatchDialogState extends State<BumpMatchDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _secondsRemaining = 5; 
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..reverse(from: 1.0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _finalize(); 
          }
        });
      }
    });
  }

  void _finalize() {
    if (mounted) {
      widget.onConfirm();
      Navigator.of(context).pop(); 
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.partnerData;
    final int modeIndex = int.tryParse(data['modeIndex']?.toString() ?? '0') ?? 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24), // 좌우 여백 조금 더 줌
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // 상단 패딩 늘림
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(28), // 더 둥글게
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀
            Text(
              "BUMP MATCHED!",
              style: GoogleFonts.outfit(
                color: const Color(0xFF4B6EFF),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 30),

            // [핵심 디자인 수정] 명함 비율 고정 및 그림자 효과
            // FittedBox: 명함 디자인이 깨지지 않고 비율 그대로 축소됨
            FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 340, // 명함의 기준 너비 (이 너비 안에서 디자인됨)
                child: AspectRatio(
                  aspectRatio: 1.586, // ID-1 카드 표준 비율 (신용카드 비율)
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        // 명함 자체의 그림자 (입체감)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CardRenderer(
                        data: data,
                        modeIndex: modeIndex,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 36),

            // 타이머 UI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("자동 저장 중...", style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                Text("$_secondsRemaining초", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            
            // 진행바
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _controller.value,
                    backgroundColor: Colors.white10,
                    color: const Color(0xFF4B6EFF),
                    minHeight: 6,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),

            // 저장 버튼 (고급스러운 스타일)
            SizedBox(
              width: double.infinity,
              height: 50, 
              child: ElevatedButton(
                onPressed: _finalize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8F8F8), // 오프화이트
                  foregroundColor: const Color(0xFF121212), // 진한 검정
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14), 
                  ),
                  splashFactory: InkRipple.splashFactory,
                ),
                child: Text(
                  "지금 바로 저장",
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}