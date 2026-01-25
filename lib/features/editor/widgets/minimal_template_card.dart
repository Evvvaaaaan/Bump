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
    final safeData = _flattenData(data);
    
    // 1. 헤더 정보 추출 (이름, 직함, 회사, MBTI, 로고)
    final name = _getString(safeData, 'name') ?? 'NAME';
    final logoUrl = _getString(safeData, 'logoUrl');
    
    // 서브텍스트 구성
    String? subtitle; // 직함 or MBTI
    String? thirdLine; // 회사명 (Business 전용)

    if (modeIndex == 0) { // Business
      subtitle = _getString(safeData, 'role'); // 직함
      thirdLine = _getString(safeData, 'company'); // 회사명
    } else if (modeIndex == 1) { // Social
      subtitle = _getString(safeData, 'mbti')?.toUpperCase(); // MBTI
    } else { // Private
      subtitle = "Private Contact";
    }

    // 2. 리스트 정보 추출 (모든 필드 포함)
    final contactItems = _getSmartContactItems(safeData);

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [헤더 영역] 이름, 직함, 회사명, 로고
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.notoSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
                      ],
                      if (thirdLine != null) ...[ // 회사명 표시
                        const SizedBox(height: 2),
                        Text(thirdLine, style: GoogleFonts.notoSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
                      ],
                    ],
                  ),
                ),
                if (logoUrl != null)
                  CircleAvatar(radius: 22, backgroundImage: NetworkImage(logoUrl), backgroundColor: Colors.transparent)
                else if (modeIndex == 0) // 로고 없으면 비즈니스 아이콘
                  const Icon(Icons.business, size: 40, color: Colors.black12),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Colors.black12),
            const SizedBox(height: 16),

            // [리스트 영역] 스크롤 적용 + 모든 정보 표시
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: contactItems.isNotEmpty 
                    ? contactItems.map((item) => _buildContactRow(item)).toList()
                    : [const Text("표시할 정보가 없습니다.", style: TextStyle(color: Colors.black38, fontSize: 12))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [데이터 추출 로직 수정] 요청하신 모든 필드를 포함
  List<Map<String, dynamic>> _getSmartContactItems(Map<String, dynamic> d) {
    List<Map<String, dynamic>> items = [];
    
    // 데이터 가져오기
    final phone = _getString(d, 'phone');
    final email = _getString(d, 'email');
    final website = _getString(d, 'website');
    final address = _getString(d, 'address');
    final instagram = _getString(d, 'instagram');
    final kakao = _getString(d, 'kakaoId') ?? _getString(d, 'kakao');
    final birthdate = _getString(d, 'birthdate');

    if (modeIndex == 0) { // Business: 업무전화, 업무이메일, 웹사이트
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
      if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website});
    
    } else if (modeIndex == 1) { // Social: 생일, 인스타, 카카오
      if (birthdate != null) items.add({'icon': Icons.cake_outlined, 'value': birthdate, 'url': null});
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
    
    } else { // Private: 개인전화, 개인이메일, 집주소
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
      if (address != null) items.add({'icon': Icons.home_outlined, 'value': address, 'url': null});
    }
    
    return items;
  }

  Widget _buildContactRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: GestureDetector(
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Row(
          children: [
            Icon(item['icon'], size: 16, color: Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['value'], 
                style: GoogleFonts.notoSans(fontSize: 13, color: Colors.black87), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis 
              )
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _flattenData(Map<String, dynamic> source) {
    Map<String, dynamic> result = Map.from(source);
    if (source['profile'] != null && source['profile'] is Map) {
      result.addAll(Map<String, dynamic>.from(source['profile']));
    }
    return result;
  }
  String? _getString(Map<String, dynamic> d, String key) { final val = d[key]; if (val == null || val.toString().trim().isEmpty) return null; return val.toString(); }
  String _shortenUrl(String url) => url.replaceFirst(RegExp(r'https?://(www\.)?'), '');
  Future<void> _launch(String url) async { final uri = Uri.parse(url.startsWith('http') || url.startsWith('tel') || url.startsWith('mailto') || url.startsWith('kakaotalk') ? url : 'https://$url'); if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); }
}