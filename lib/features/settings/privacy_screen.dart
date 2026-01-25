import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

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
          "개인정보 처리방침",
          style: GoogleFonts.notoSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "BUMP 개인정보 처리방침",
              style: GoogleFonts.outfit(
                color: const Color(0xFF4B6EFF),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "시행일자: 2026년 1월 26일",
              style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 30),

            _buildSection(
              "1. 총칙",
              "BUMP(이하 '회사')는 이용자의 개인정보를 중요시하며, '개인정보 보호법' 및 '정보통신망 이용촉진 및 정보보호 등에 관한 법률'을 준수하고 있습니다."
            ),
            _buildSection(
              "2. 수집하는 개인정보의 항목",
              "회사는 회원가입, 원활한 고객상담, 서비스 제공을 위해 아래와 같은 개인정보를 수집하고 있습니다.\n\n"
              "• 필수항목: 로그인 ID(이메일), 프로필 사진, 닉네임, 기기 고유 식별자(Device ID)\n"
              "• 선택항목: 직업, 회사명, 연락처, SNS 계정 정보\n"
              "• 서비스 이용 과정에서 생성되는 정보: 접속 로그, 쿠키, 접속 IP 정보, 불량 이용 기록"
            ),
            _buildSection(
              "3. 개인정보의 수집 및 이용 목적",
              "회사는 수집한 개인정보를 다음의 목적을 위해 활용합니다.\n\n"
              "• 서비스 제공: 위치 기반 명함 교환 매칭, 콘텐츠 제공\n"
              "• 회원 관리: 본인확인, 개인 식별, 불량회원의 부정 이용 방지, 가입 의사 확인\n"
              "• 신규 서비스 개발 및 마케팅: 신규 서비스 개발, 접속 빈도 파악, 회원의 서비스 이용에 대한 통계"
            ),
            _buildSection(
              "4. 위치기반 서비스와 개인정보",
              "본 서비스는 이용자의 위치 정보를 기반으로 주변 사용자를 탐색하는 기능을 제공합니다.\n"
              "• 위치 정보는 앱 실행 시 또는 'BUMP' 기능 활성화 시에만 수집되며, 매칭이 완료되거나 앱 종료 시 즉시 파기되거나 익명화 처리됩니다.\n"
              "• 위치 정보는 서버에 영구 저장되지 않습니다."
            ),
            _buildSection(
              "5. 개인정보의 보유 및 이용 기간",
              "원칙적으로 개인정보 수집 및 이용 목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다. 단, 관계법령의 규정에 의하여 보존할 필요가 있는 경우 회사는 아래와 같이 관계법령에서 정한 일정한 기간 동안 회원정보를 보관합니다.\n\n"
              "• 로그인 기록: 3개월 (통신비밀보호법)\n"
              "• 소비자의 불만 또는 분쟁처리에 관한 기록: 3년 (전자상거래 등에서의 소비자보호에 관한 법률)"
            ),
            _buildSection(
              "6. 이용자 및 법정대리인의 권리와 행사 방법",
              "이용자는 언제든지 등록되어 있는 자신의 개인정보를 조회하거나 수정할 수 있으며 가입 해지를 요청할 수 있습니다. 앱 내 '설정 > 계정 관리' 메뉴를 통해 탈퇴가 가능합니다."
            ),
            _buildSection(
              "7. 개인정보 보호책임자",
              "회사는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위하여 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.\n\n"
              "• 이메일: vmfhrmfoald36@gmail.com"
            ),
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
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
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}