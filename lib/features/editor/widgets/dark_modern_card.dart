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
    // 1. 데이터 평탄화 (숨어있는 데이터 꺼내기)
    final Map<String, dynamic> safeData = _flattenData(data);

    final name = _getString(safeData, 'name') ?? 'NAME';
    
    // 2. 스마트 자막 (직함 없으면 MBTI 표시)
    String? subtitle = _getString(safeData, 'role');
    if (subtitle == null && _getString(safeData, 'mbti') != null) {
      subtitle = _getString(safeData, 'mbti')?.toUpperCase();
    }
    subtitle ??= "CONTACT";

    String? logoUrl = _getString(safeData, 'logoUrl');
    
    // 3. 스마트 리스트 (있는 데이터 우선 표시)
    List<Map<String, dynamic>> contactItems = _getSmartContactItems(safeData);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF252525), Color(0xFF000000)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          // 배경 데코레이션 (모던한 원형 그라디언트)
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.1),
                blurRadius: 50,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 이름 영역
                      Text(name, style: GoogleFonts.notoSans(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      // 자막 영역 (색상 포인트)
                      Text(subtitle, style: GoogleFonts.notoSans(fontSize: 13, color: const Color(0xFF64B5F6), fontWeight: FontWeight.w600)),
                      
                      const SizedBox(height: 20),
                      
                      // 연락처 리스트
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: contactItems.map((item) => _buildContactRow(item)).toList(),
                      ),
                    ],
                  ),
                ),
                
                // 로고 또는 아이콘 영역
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (logoUrl != null)
                        Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                            image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                          ),
                        )
                      else
                        Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white10,
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Icon(
                            (safeData['instagram'] != null || safeData['mbti'] != null) ? Icons.person_outline : Icons.business, 
                            color: Colors.white70, size: 28
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // [스마트 데이터 추출 로직]
  List<Map<String, dynamic>> _getSmartContactItems(Map<String, dynamic> d) {
    List<Map<String, dynamic>> items = [];

    final phone = _getString(d, 'phone');
    final email = _getString(d, 'email');
    final website = _getString(d, 'website');
    final company = _getString(d, 'company');
    final instagram = _getString(d, 'instagram');
    final kakao = _getString(d, 'kakaoId') ?? _getString(d, 'kakao');
    final birthdate = _getString(d, 'birthdate');
    final address = _getString(d, 'address');

    // Business
    if (modeIndex == 0) {
      if (company != null) items.add({'icon': Icons.business, 'value': company, 'url': null});
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
      if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website});
      // Fallback
      if (items.isEmpty) {
        if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
        if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      }
    } 
    // Social
    else if (modeIndex == 1) {
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      if (birthdate != null) items.add({'icon': Icons.cake_outlined, 'value': birthdate, 'url': null});
      if (items.isEmpty && phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
    } 
    // Private
    else {
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      if (address != null) items.add({'icon': Icons.home_outlined, 'value': address, 'url': null});
      if (items.isEmpty && email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
    }

    // 최후의 보루
    if (items.isEmpty) {
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
    }

    return items;
  }

  Widget _buildContactRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Row(
          children: [
            Icon(item['icon'], size: 14, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(child: Text(item['value'], style: GoogleFonts.notoSans(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w300), maxLines: 1, overflow: TextOverflow.ellipsis)),
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

  String? _getString(Map<String, dynamic> d, String key) {
    final val = d[key];
    if (val == null || val.toString().trim().isEmpty) return null;
    return val.toString();
  }
  String _shortenUrl(String url) => url.replaceFirst(RegExp(r'https?://(www\.)?'), '');
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url.startsWith('http') || url.startsWith('tel') || url.startsWith('mailto') || url.startsWith('kakaotalk') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}