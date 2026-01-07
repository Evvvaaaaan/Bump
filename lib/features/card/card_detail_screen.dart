import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardDetailScreen extends StatelessWidget {
  // 생성자에서 데이터를 받도록 수정
  final Map<String, dynamic> cardData;

  const CardDetailScreen({
    super.key, 
    this.cardData = const {}, // 기본값
  });

  @override
  Widget build(BuildContext context) {
    // 데이터가 비어있을 경우 처리
    final name = cardData['name'] ?? 'Unknown';
    final company = cardData['company'] ?? '-';
    final role = cardData['role'] ?? '-';
    final phone = cardData['phone'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text("명함 상세"),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 명함 카드 디자인
            Container(
              width: 320,
              height: 190,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A), // 비즈니스 컬러
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text("$role | $company", style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(phone, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}