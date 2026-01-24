import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum PaperType { white, kraft, linen }

class PaperTextureCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;
  final PaperType type;

  const PaperTextureCard({
    super.key, 
    required this.data,
    required this.modeIndex,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 데이터 평탄화 (숨어있는 데이터 꺼내기)
    final Map<String, dynamic> safeData = _flattenData(data);

    // 배경 설정
    Color bgColor; Color textColor; Color accentColor; String textureUrl;
    switch (type) {
      case PaperType.white:
        bgColor = const Color(0xFFFDFBF7); textColor = const Color(0xFF5D4037); accentColor = const Color(0xFFD4AF37);
        textureUrl = "https://www.transparenttextures.com/patterns/cream-paper.png";
        break;
      case PaperType.kraft:
        bgColor = const Color(0xFFD7CCC8); textColor = const Color(0xFF3E2723); accentColor = const Color(0xFF5D4037);
        textureUrl = "https://www.transparenttextures.com/patterns/cardboard-flat.png";
        break;
      case PaperType.linen:
        bgColor = const Color(0xFFEFEBE2); textColor = const Color(0xFF212121); accentColor = const Color(0xFF424242);
        textureUrl = "https://www.transparenttextures.com/patterns/canvas-orange.png";
        break;
    }

    final name = _getString(safeData, 'name') ?? '이름 없음';
    
    // 2. 스마트 자막 (직함 없으면 MBTI 표시)
    String? subtitle = _getString(safeData, 'role');
    if (subtitle == null && _getString(safeData, 'mbti') != null) {
      subtitle = _getString(safeData, 'mbti')?.toUpperCase();
    }

    String? logoUrl = _getString(safeData, 'logoUrl');
    
    // 3. 스마트 리스트 (있는 데이터 우선 표시)
    List<Map<String, dynamic>> contactItems = _getSmartContactItems(safeData);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        image: DecorationImage(image: NetworkImage(textureUrl), repeat: ImageRepeat.repeat, opacity: 0.4),
      ),
      child: Stack(
        children: [
          Positioned(top: 70, bottom: 70, left: 0, right: 0, child: Container(color: textColor.withOpacity(0.03))),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: GoogleFonts.nanumMyeongjo(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(subtitle, style: GoogleFonts.nanumMyeongjo(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor)),
                      ],
                      const SizedBox(height: 12),
                      Container(width: 40, height: 1.5, color: accentColor),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: contactItems.map((item) => _buildContactRow(item, textColor)).toList()
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (logoUrl != null)
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(bgColor, BlendMode.modulate),
                          child: Container(width: 50, height: 50, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.contain))),
                        )
                      else
                        // 데이터 종류에 따라 아이콘 변경
                        Icon(
                          (safeData['instagram'] != null || safeData['mbti'] != null) ? Icons.local_florist : Icons.spa, 
                          size: 40, 
                          color: accentColor
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

  // [스마트 데이터 추출]
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

    // Business 모드 우선
    if (modeIndex == 0) {
      if (company != null) items.add({'icon': Icons.business, 'value': company, 'url': null});
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.mail_outline, 'value': email, 'url': "mailto:$email"});
      if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website});
      
      // 비즈니스 정보 없으면 소셜 정보 표시
      if (items.isEmpty) {
        if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
        if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      }
    } 
    // Social 모드 우선
    else if (modeIndex == 1) {
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      if (birthdate != null) items.add({'icon': Icons.cake, 'value': birthdate, 'url': null});
      
      // 소셜 정보 없으면 전화번호 표시
      if (items.isEmpty && phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
    } 
    // Private 모드
    else {
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (address != null) items.add({'icon': Icons.home, 'value': address, 'url': null});
      if (items.isEmpty && email != null) items.add({'icon': Icons.mail_outline, 'value': email, 'url': "mailto:$email"});
    }

    // 최후의 보루: 비어있으면 뭐라도 표시
    if (items.isEmpty) {
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
    }

    return items;
  }

  Widget _buildContactRow(Map<String, dynamic> item, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: GestureDetector(
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item['icon'], size: 12, color: color.withOpacity(0.7)),
            const SizedBox(width: 8),
            Flexible(child: Text(item['value'], style: GoogleFonts.nanumGothic(fontSize: 10, color: color, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
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