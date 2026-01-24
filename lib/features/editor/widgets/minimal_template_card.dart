import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MinimalTemplateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;

  const MinimalTemplateCard({
    super.key, 
    required this.data,
    required this.modeIndex, 
  });

  @override
  Widget build(BuildContext context) {
    final name = _getValue('name');
    String? subtitle;
    String? logoUrl; // [NEW] 회사 로고
    List<Map<String, dynamic>> contactItems = [];

    // =========================================================
    // [1] Business Mode (업무)
    // =========================================================
    if (modeIndex == 0) {
      subtitle = _getValue('role'); 
      logoUrl = _getValue('logoUrl'); // [NEW] 로고 데이터
      
      final company = _getValue('company');
      final phone = _getValue('phone');
      final email = _getValue('email');
      final website = _getValue('website');

      if (phone != null) contactItems.add({'icon': Icons.phone, 'label': 'TEL', 'value': phone, 'url': "tel:$phone"});
      if (email != null) contactItems.add({'icon': Icons.mail_outline, 'label': 'MAIL', 'value': email, 'url': "mailto:$email"});
      if (website != null) contactItems.add({'icon': Icons.language, 'label': 'WEB', 'value': _shortenUrl(website), 'url': website});
      if (company != null) contactItems.add({'icon': Icons.business, 'label': 'OFFICE', 'value': company, 'url': null});
    } 
    // =========================================================
    // [2] Social Mode (사교)
    // =========================================================
    else if (modeIndex == 1) {
      // [수정] TMI 삭제 -> MBTI를 부제목으로 고정
      subtitle = _getValue('mbti');
      
      final instagram = _getValue('instagram');
      final kakao = _getValue('kakaoId');
      final birth = _getValue('birthdate'); // YYYY-MM-DD

      if (instagram != null) contactItems.add({'icon': FontAwesomeIcons.instagram, 'label': 'INSTAGRAM', 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      
      // [수정됨] 카카오톡 URL 설정 로직 추가
      if (kakao != null) {
        contactItems.add({
          'icon': FontAwesomeIcons.solidComment,
          'label': 'KAKAO',
          'value': kakao,
          // http로 시작하면(오픈프로필 등) 링크 이동, 아니면(ID) 앱 실행 시도
          'url': kakao.startsWith('http') ? kakao : "kakaotalk://"
        });
      }
      
      // [수정] 생일 포맷이 YYYY-MM-DD로 들어오므로 그대로 표시하거나 가공
      if (birth != null) contactItems.add({'icon': Icons.cake_outlined, 'label': 'BDAY', 'value': birth, 'url': null});
    }
    // =========================================================
    // [3] Private Mode (개인)
    // =========================================================
    else {
      subtitle = "PRIVATE CARD";
      
      final phone = _getValue('phone');
      final address = _getValue('address');
      final email = _getValue('email');
      // [수정] Discord 삭제됨

      if (phone != null) contactItems.add({'icon': Icons.phone, 'label': 'MOBILE', 'value': phone, 'url': "tel:$phone"});
      if (address != null) contactItems.add({'icon': Icons.home, 'label': 'HOME', 'value': address, 'url': null});
      if (email != null) contactItems.add({'icon': Icons.email, 'label': 'EMAIL', 'value': email, 'url': "mailto:$email"});
    }

    bool isSparse = contactItems.length <= 2;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFEBE6D8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Stack(
        children: [
          // 배경 장식
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(border: Border.all(color: Colors.black54, width: 0.5)),
            ),
          ),
          
          // [NEW] 회사 로고 표시 (Business 모드일 때만)
          if (logoUrl != null && modeIndex == 0)
            Positioned(
              top: 20,
              right: 24,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                  border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: isSparse
                ? _buildCenteredLayout(name, subtitle, contactItems)
                : _buildFullLayout(name, subtitle, contactItems),
          ),
        ],
      ),
    );
  }

  // [레이아웃 A] 중앙 정렬
  Widget _buildCenteredLayout(String? name, String? subtitle, List<Map<String, dynamic>> items) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (name != null)
          Text(
            name.toUpperCase(),
            style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.5),
            textAlign: TextAlign.center,
          ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(20)),
            child: Text(
              subtitle.toUpperCase(),
              style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: items.map((item) => _buildLargeIconBtn(item)).toList(),
        ),
      ],
    );
  }

  // [레이아웃 B] 좌측 정렬 (제공해주신 코드 레이아웃 유지)
  Widget _buildFullLayout(String? name, String? subtitle, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 2),
        if (name != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name.toUpperCase(),
              style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1.2),
            ),
          ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle.toUpperCase(),
            style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 0.5),
          ),
        ],
        const Spacer(flex: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: items.map((item) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildSmallIcon(item),
              )).toList(),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.map((item) => _buildContactRow(item['label'], item['value'])).toList(),
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  // Helper Widgets
  Widget _buildLargeIconBtn(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.05)),
          child: Icon(item['icon'], size: 28, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildSmallIcon(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => item['url'] != null ? _launch(item['url']) : null,
      child: Icon(item['icon'], size: 24, color: Colors.black),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$label ", style: GoogleFonts.lato(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black54), textAlign: TextAlign.left,),
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.lato(fontSize: 10, color: Colors.black, fontWeight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // [수정됨] URL 실행 로직 (카카오톡 스킴 및 외부 앱 실행 지원)
  Future<void> _launch(String url) async {
    final uri = Uri.parse(
      (url.startsWith('http') || url.startsWith('tel') || url.startsWith('mailto') || url.startsWith('kakaotalk')) 
      ? url 
      : 'https://$url'
    );
    
    // 외부 앱 실행 모드 사용 (카카오톡 앱 열기 위해 필수)
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String? _getValue(String key) {
    final val = data[key]?.toString();
    return (val == null || val.trim().isEmpty) ? null : val;
  }
  
  String _shortenUrl(String url) {
    return url.replaceFirst('https://', '').replaceFirst('http://', '').replaceFirst('www.', '');
  }
}