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
    required this.modeIndex, // [필수] 모드 인덱스 받기
  });

  @override
  Widget build(BuildContext context) {
    // 1. 데이터 병합 (Flatten)
    final safeData = _flattenData(data);
    final name = _getString(safeData, ['name', 'nickname']) ?? 'NAME';
    final logoUrl = _getString(safeData, ['logoUrl', 'photoUrl']);

    // 2. 헤더 정보 설정 (모드별 분기)
    String? subtitle;
    String? extraHeaderInfo;
    IconData modeIcon;

    if (modeIndex == 0) { // Business
      subtitle = _getString(safeData, ['role', 'job']); // 직함
      extraHeaderInfo = _getString(safeData, ['company', 'org']); // 회사명
      modeIcon = Icons.domain;
    } else if (modeIndex == 1) { // Social
      subtitle = _getString(safeData, ['mbti'])?.toUpperCase(); // MBTI
      // 생일이 있으면 추가 정보로 표시
      final birth = _getString(safeData, ['birthdate', 'birth']);
      if (birth != null) extraHeaderInfo = "🎂 $birth"; 
      modeIcon = Icons.diversity_3;
    } else { // Private
      subtitle = "Private Mode";
      modeIcon = Icons.home_filled;
    }

    // 3. 연락처 아이템 리스트 생성
    final contactItems = _getSmartContactItems(safeData);

    return AspectRatio(
      aspectRatio: 1.586, // 신용카드 비율
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E2E2E), Color(0xFF000000)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), 
              blurRadius: 20, 
              offset: const Offset(0, 10)
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // [배경 그래픽]
              Positioned(
                right: -80, top: -80,
                child: Opacity(opacity: 0.05, child: Icon(Icons.hexagon_outlined, size: 300, color: Colors.white)),
              ),
              Positioned(
                left: -60, bottom: -60,
                child: Opacity(opacity: 0.05, child: Icon(Icons.change_history, size: 250, color: Colors.white)),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [헤더 영역] 로고 + 자막
                    Row(
                      children: [
                        if (logoUrl != null)
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                              border: Border.all(color: Colors.white12),
                            ),
                          )
                        else
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                            child: Icon(modeIcon, color: Colors.white70, size: 24),
                          ),
                        const SizedBox(width: 16),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (subtitle != null)
                                Text(subtitle, style: GoogleFonts.notoSans(fontSize: 14, color: const Color(0xFF64B5F6), fontWeight: FontWeight.w600)),
                              if (extraHeaderInfo != null)
                                Text(extraHeaderInfo, style: GoogleFonts.notoSans(fontSize: 12, color: Colors.white60)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    // [본문 영역] 이름 + 리스트 (스크롤 가능)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // 이름 (자동 크기 조절)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                name,
                                style: GoogleFonts.notoSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 연락처 리스트
                            if (contactItems.isNotEmpty)
                              Column(
                                children: contactItems.map((item) => _buildContactRow(item)).toList(),
                              )
                            else
                              const Text("정보 없음", style: TextStyle(color: Colors.white38, fontSize: 12)),
                            
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- [로직 함수들] ---

  // 1. 모드별 보여줄 정보 필터링
  List<Map<String, dynamic>> _getSmartContactItems(Map<String, dynamic> d) {
    List<Map<String, dynamic>> items = [];
    
    // 데이터 추출 (키 이름 유연하게)
    final phone = _getString(d, ['phone', 'mobile']);
    final email = _getString(d, ['email', 'mail']);
    final website = _getString(d, ['website', 'web', 'blog']);
    final address = _getString(d, ['address', 'addr']);
    final instagram = _getString(d, ['instagram', 'insta']);
    final kakao = _getString(d, ['kakaoId', 'kakao', 'kakaotalk']);
    final birthdate = _getString(d, ['birthdate', 'birth']);

    if (modeIndex == 0) { // Business
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
      if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website});
      if (address != null) items.add({'icon': Icons.location_on_outlined, 'value': address, 'url': null}); // 주소 추가
    
    } else if (modeIndex == 1) { // Social
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"}); // 카톡 URL 스킴 확인 필요
      if (birthdate != null) items.add({'icon': Icons.cake_outlined, 'value': birthdate, 'url': null});
      // 소셜이어도 폰 번호가 있으면 맨 뒤에 표시 (선택사항)
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
    
    } else { // Private
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
        // URL이 있으면 실행, 없으면 클릭 무시
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Row(
          children: [
            Icon(item['icon'], size: 16, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['value'], 
                style: GoogleFonts.notoSans(
                  fontSize: 13, 
                  color: Colors.white.withOpacity(0.9), 
                  fontWeight: FontWeight.w400
                ), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              )
            ),
          ],
        ),
      ),
    );
  }

  // 데이터 병합 (Flatten)
  Map<String, dynamic> _flattenData(Map<String, dynamic> source) {
    Map<String, dynamic> result = Map.from(source);
    if (source['profile'] != null && source['profile'] is Map) {
      result.addAll(Map<String, dynamic>.from(source['profile']));
    }
    return result;
  }

  // 여러 키 중 하나라도 있으면 반환 (대소문자 무시)
  String? _getString(Map<String, dynamic> d, List<String> keys) {
    for (var key in keys) {
      if (d[key] != null && d[key].toString().isNotEmpty) return d[key].toString();
      // 대소문자 무시 검색
      for (var k in d.keys) {
        if (k.toLowerCase() == key.toLowerCase() && d[k].toString().isNotEmpty) {
          return d[k].toString();
        }
      }
    }
    return null;
  }

  String _shortenUrl(String url) => url.replaceFirst(RegExp(r'https?://(www\.)?'), '');

  Future<void> _launch(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http') && !url.startsWith('tel') && !url.startsWith('mailto') && !url.startsWith('sms') && !url.startsWith('kakaotalk')) {
      finalUrl = 'https://$url';
    }
    try {
      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("링크 실행 실패: $e");
    }
  }
}