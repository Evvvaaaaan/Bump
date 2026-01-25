import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "이용약관",
          style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "BUMP 서비스 이용약관",
              style: GoogleFonts.outfit(
                color: const Color(0xFF4B6EFF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "최종 수정일: 2026년 1월 26일",
              style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 30),
            
            // 약관 본문
            _buildTermSection(
              "제 1 조 (목적)",
              "본 약관은 BUMP(이하 '회사')가 제공하는 위치 기반 명함 교환 서비스(이하 '서비스')의 이용조건 및 절차, 이용자와 회사의 권리, 의무, 책임사항을 규정함을 목적으로 합니다."
            ),
            _buildTermSection(
              "제 2 조 (용어의 정의)",
              "1. '서비스'란 모바일 기기를 통해 주변 사용자를 탐색하고 디지털 명함을 교환하는 모든 제반 서비스를 의미합니다.\n"
              "2. '이용자'란 본 약관에 따라 회사가 제공하는 서비스를 이용하는 회원을 말합니다."
            ),
            _buildTermSection(
              "제 3 조 (위치기반 서비스의 내용)",
              "회사는 위치정보사업자로부터 제공받은 위치정보를 이용하여, 이용자의 현재 위치를 기준으로 일정 반경 내의 다른 이용자를 탐색하고 매칭하는 서비스를 제공합니다."
            ),
            _buildTermSection(
              "제 4 조 (개인정보의 보호)",
              "회사는 관련 법령이 정하는 바에 따라 이용자의 개인정보를 보호하기 위해 노력합니다. 개인정보의 보호 및 사용에 대해서는 관련 법령 및 회사의 개인정보처리방침이 적용됩니다."
            ),
            _buildTermSection(
              "제 5 조 (서비스의 중단)",
              "회사는 시스템 점검, 증설 및 교체, 국가비상사태, 정전 등 정상적인 서비스 제공이 불가능한 경우 서비스의 전부 또는 일부를 일시적으로 중단할 수 있습니다."
            ),
            _buildTermSection(
              "제 6 조 (책임의 한계)",
              "회사는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임이 면제됩니다."
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.notoSans(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6, // 줄 간격을 넉넉하게 주어 가독성 확보
            ),
          ),
        ],
      ),
    );
  }
}