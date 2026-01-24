import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class LandscapeCardScreen extends StatefulWidget {
  final Map<String, dynamic> cardData;

  const LandscapeCardScreen({super.key, required this.cardData});

  @override
  State<LandscapeCardScreen> createState() => _LandscapeCardScreenState();
}

class _LandscapeCardScreenState extends State<LandscapeCardScreen> {
  @override
  void initState() {
    super.initState();
    // [몰입 모드] 상단바(상태바)와 하단바 숨기기 -> 꽉 찬 화면
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // 화면 나갈 때 다시 원래대로 상단바 복구
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 데이터 파싱 (다이나믹 카드와 동일한 로직)
    final theme = widget.cardData['theme'] as Map<String, dynamic>? ?? {};
    final List<dynamic> colorHexes = theme['colors'] ?? ['#4B6EFF', '#82B1FF'];
    
    List<Color> colors = colorHexes.map((hex) {
      String hexStr = hex.toString().replaceAll('#', '');
      if (hexStr.length == 6) hexStr = 'FF$hexStr';
      return Color(int.parse('0x$hexStr'));
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. 화면 전체를 90도 회전
          Center(
            child: RotatedBox(
              quarterTurns: 1, // 시계 방향 90도 회전
              child: Container(
                // 화면 비율에 맞춰 꽉 차게 (가로 명함 비율 1.6 : 1 정도)
                width: MediaQuery.of(context).size.height * 0.85, 
                height: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: colors.isEmpty ? [Colors.blue, Colors.lightBlue] : colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (colors.isNotEmpty ? colors.first : Colors.blue).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 로고나 회사명 (우측 상단 느낌)
                    Align(
                      alignment: Alignment.topRight,
                      child: Opacity(
                        opacity: 0.5,
                        child: Text(
                          widget.cardData['company'] ?? 'BUMP',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ),
                    ),
                    const Spacer(),
                    
                    // 프로필 정보
                    Row(
                      children: [
                         CircleAvatar(
                          radius: 50, // 더 크게
                          backgroundColor: Colors.white24,
                          backgroundImage: widget.cardData['photoUrl'] != null 
                              ? NetworkImage(widget.cardData['photoUrl']) 
                              : null,
                          child: widget.cardData['photoUrl'] == null 
                              ? const Icon(Icons.person, color: Colors.white, size: 50) : null,
                        ),
                        const SizedBox(width: 30),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cardData['name'] ?? '이름 없음',
                                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${widget.cardData['role'] ?? ''}  |  ${widget.cardData['department'] ?? ''}",
                                style: const TextStyle(color: Colors.white70, fontSize: 20),
                              ),
                              const SizedBox(height: 20),
                              // 연락처 정보 크게
                              _buildBigInfo(Icons.phone, widget.cardData['phone']),
                              const SizedBox(height: 8),
                              _buildBigInfo(Icons.email, widget.cardData['email']),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // 하단 QR 코드 (장식용)
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Icon(Icons.qr_code_2, size: 60, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. 닫기 버튼 (회전하지 않고 화면 상단에 고정)
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigInfo(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox();
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 15),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ],
    );
  }
}