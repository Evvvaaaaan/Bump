import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DarkModernCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;

  const DarkModernCard({
    super.key, 
    required this.data,
    required this.modeIndex, 
  });

  @override
  Widget build(BuildContext context) {
    final name = _getValue('name') ?? 'NAME';
    String? subtitle;
    String? logoUrl = _getValue('logoUrl');
    List<Map<String, dynamic>> contactItems = [];

    // =========================================================
    // 데이터 매핑
    // =========================================================
    if (modeIndex == 0) { // Business
      subtitle = _getValue('role');
      final company = _getValue('company');
      final phone = _getValue('phone');
      final email = _getValue('email');
      final website = _getValue('website');

      if (phone != null) contactItems.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) contactItems.add({'icon': Icons.mail_outline, 'value': email, 'url': "mailto:$email"});
      if (website != null) contactItems.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website});
      if (company != null) contactItems.add({'icon': Icons.business, 'value': company, 'url': null});
    } 
    else if (modeIndex == 1) { // Social
      subtitle = _getValue('mbti');
      final instagram = _getValue('instagram');
      final kakao = _getValue('kakaoId');
      final birth = _getValue('birthdate');

      if (instagram != null) contactItems.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) contactItems.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': kakao.startsWith('http') ? kakao : "kakaotalk://"});
      if (birth != null) contactItems.add({'icon': Icons.cake_outlined, 'value': birth, 'url': null});
    }
    else { // Private
      subtitle = "PRIVATE";
      final phone = _getValue('phone');
      final address = _getValue('address');
      final email = _getValue('email');

      if (phone != null) contactItems.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (address != null) contactItems.add({'icon': Icons.home, 'value': address, 'url': null});
      if (email != null) contactItems.add({'icon': Icons.email, 'value': email, 'url': "mailto:$email"});
    }

    return Container(
      width: double.infinity,
      // [수정 1] 고정 높이(height: 220) 제거하고 최소 높이 설정
      // 내용이 많으면 자동으로 늘어납니다.
      constraints: const BoxConstraints(minHeight: 220), 
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2C), Color(0xFF000000)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      // [수정 2] Stack 대신 ClipRRect로 감싸서 내용이 넘칠 때 잘리거나 배경과 맞게 함
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 배경 패턴
            Positioned(
              right: -50, top: -50,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              // [수정 3] IntrinsicHeight: 양쪽 컬럼의 높이를 동일하게 맞춤 (Spacer 작동을 위해 필수)
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // [왼쪽 영역] 정보
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.notoSans(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 12),
                          Container(width: 40, height: 2, color: Colors.white30),
                          const SizedBox(height: 16),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: contactItems.map((item) => _buildContactRow(item)).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // [오른쪽 영역] 버튼 및 로고
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                         
                          // [수정 4] 유동적인 공간 확보 (Flexible Space)
                          const Spacer(),

                          // 하단 로고
                          if (logoUrl != null && logoUrl.isNotEmpty)
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(logoUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Opacity(
                              opacity: 0.1,
                              child: Icon(Icons.hexagon, size: 80, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: GestureDetector(
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Row(
          children: [
            Icon(item['icon'], size: 14, color: Colors.white70),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item['value'],
                style: GoogleFonts.notoSans(
                  fontSize: 11, 
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(
      (url.startsWith('http') || url.startsWith('tel') || url.startsWith('mailto') || url.startsWith('kakaotalk')) 
      ? url 
      : 'https://$url'
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String? _getValue(String key) {
    final val = data[key]?.toString();
    return (val == null || val.trim().isEmpty) ? null : val;
  }

  String _shortenUrl(String url) {
    return url.replaceFirst('https://', '').replaceFirst('http://', '').replaceFirst('www.', '');
  }
}