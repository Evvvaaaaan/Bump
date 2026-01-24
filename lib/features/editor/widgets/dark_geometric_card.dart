import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DarkGeometricCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;

  const DarkGeometricCard({
    super.key, 
    required this.data,
    required this.modeIndex, 
  });

  @override
  Widget build(BuildContext context) {
    // 1. 데이터 평탄화 (어디 숨어있든 다 꺼냄)
    final Map<String, dynamic> safeData = _flattenData(data);

    final name = _getString(safeData, 'name') ?? '이름 없음';
    
    // 2. [스마트 자막 로직]
    // 모드가 Business여도 직함이 없으면 MBTI를 보여줍니다.
    String? subtitle = _getString(safeData, 'role');
    if (subtitle == null && _getString(safeData, 'mbti') != null) {
      subtitle = _getString(safeData, 'mbti')?.toUpperCase();
    }
    // 그래도 없으면 기본 텍스트
    subtitle ??= "CONTACT INFO";

    String? logoUrl = _getString(safeData, 'logoUrl');
    
    // 3. [스마트 리스트 로직]
    // 모드 설정이 꼬여있어도, 데이터가 있는 필드를 우선적으로 보여줍니다.
    List<Map<String, dynamic>> contactItems = _getSmartContactItems(safeData);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2C), Color(0xFF000000)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              right: -50, bottom: -30,
              child: Opacity(opacity: 0.1, child: Icon(Icons.hexagon_outlined, size: 240, color: Colors.white)),
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
                        Text(
                          name,
                          style: GoogleFonts.notoSans(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(subtitle, style: GoogleFonts.notoSans(fontSize: 14, color: const Color(0xFF4B6EFF), fontWeight: FontWeight.w600)),
                        ],
                        const SizedBox(height: 16),
                        Container(width: 30, height: 2, color: Colors.grey[700]),
                        const SizedBox(height: 16),
                        
                        // 연락처 리스트 (데이터가 있으면 무조건 표시됨)
                        if (contactItems.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: contactItems.map((item) => _buildContactRow(item)).toList(),
                          )
                        else
                          // 데이터가 정말 하나도 없을 때만 표시
                          const Text("연락처 정보 없음", style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (logoUrl != null)
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                              image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                            ),
                          )
                        else
                           Opacity(
                             opacity: 0.2, 
                             // 데이터 내용에 따라 아이콘 변경 (인스타가 있으면 사람, 아니면 빌딩)
                             child: Icon(
                               (safeData['instagram'] != null || safeData['mbti'] != null) ? Icons.emoji_people : Icons.hive, 
                               size: 56, 
                               color: Colors.white
                             )
                           ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [핵심] 스마트 데이터 추출 함수
  // 모드 인덱스만 믿지 않고, 실제 데이터가 있는지를 확인해서 리스트를 만듭니다.
  List<Map<String, dynamic>> _getSmartContactItems(Map<String, dynamic> d) {
    List<Map<String, dynamic>> items = [];

    // 1. 모든 가능한 데이터 추출
    final phone = _getString(d, 'phone');
    final email = _getString(d, 'email');
    final website = _getString(d, 'website');
    final company = _getString(d, 'company');
    
    final instagram = _getString(d, 'instagram');
    final kakao = _getString(d, 'kakaoId') ?? _getString(d, 'kakao');
    final birthdate = _getString(d, 'birthdate');
    final address = _getString(d, 'address');

    // 2. 모드에 맞춰서 넣되, 없으면 다른 데이터라도 채워넣는 로직

    // (A) Business Mode 우선 확인
    if (modeIndex == 0) {
      if (company != null) items.add({'icon': Icons.business, 'value': company, 'url': null});
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
      if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website});
      
      // 만약 위 비즈니스 정보가 하나도 없고, 소셜 정보가 있다면? -> 소셜 정보라도 보여줘라!
      if (items.isEmpty) {
        if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
        if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      }
    } 
    // (B) Social Mode 우선 확인
    else if (modeIndex == 1) {
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      if (birthdate != null) items.add({'icon': Icons.cake_outlined, 'value': birthdate, 'url': null});
      
      // 소셜 정보가 없으면 전화번호라도 보여줘라!
      if (items.isEmpty && phone != null) {
        items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      }
    } 
    // (C) Private Mode
    else {
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      if (address != null) items.add({'icon': Icons.home, 'value': address, 'url': null});
      if (items.isEmpty && email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
    }

    // 3. (최후의 보루) 위 로직을 다 거쳤는데도 리스트가 비어있다면, 있는 거 아무거나 다 넣기
    if (items.isEmpty) {
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
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
            Icon(item['icon'], size: 14, color: Colors.grey[400]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item['value'], 
                style: GoogleFonts.notoSans(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w400), 
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