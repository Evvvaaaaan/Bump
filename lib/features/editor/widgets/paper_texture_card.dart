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
    final safeData = _flattenData(data);
    
    // 스타일 설정
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
        textureUrl = "https://www.transparenttextures.com/patterns/rough-cloth.png";
        break;
    }

    // 1. 헤더 정보 추출
    final name = _getString(safeData, 'name') ?? '이름 없음';
    final logoUrl = _getString(safeData, 'logoUrl');
    
    String? subtitle;
    String? extraInfo;

    if (modeIndex == 0) { // Business
      subtitle = _getString(safeData, 'role'); 
      extraInfo = _getString(safeData, 'company'); // 회사명 추가
    } else if (modeIndex == 1) { // Social
      subtitle = _getString(safeData, 'mbti')?.toUpperCase();
    } else { // Private
      subtitle = "Private";
    }

    // 2. 리스트 정보 추출
    final contactItems = _getSmartContactItems(safeData);

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor, 
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 텍스처
              Positioned.fill(
                child: Image.network(
                  textureUrl, fit: BoxFit.cover, repeat: ImageRepeat.repeat,
                  opacity: const AlwaysStoppedAnimation(0.4),
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [헤더 영역]
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: GoogleFonts.nanumMyeongjo(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                              if (subtitle != null) ...[
                                const SizedBox(height: 6),
                                Text(subtitle, style: GoogleFonts.nanumMyeongjo(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor)),
                              ],
                              if (extraInfo != null) ...[ // 회사명
                                const SizedBox(height: 2),
                                Text(extraInfo, style: GoogleFonts.nanumMyeongjo(fontSize: 11, fontWeight: FontWeight.w500, color: textColor.withOpacity(0.8))),
                              ],
                            ],
                          ),
                        ),
                        if (logoUrl != null)
                          ColorFiltered(
                            colorFilter: ColorFilter.mode(bgColor, BlendMode.modulate),
                            child: Container(width: 44, height: 44, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.contain))),
                          )
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    Container(width: 40, height: 1.5, color: accentColor), // 구분선
                    const SizedBox(height: 16),
                    
                    // [리스트 영역] 스크롤 & 전체 정보 표시
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, 
                          children: contactItems.map((item) => _buildContactRow(item, textColor)).toList()
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

  // [데이터 추출 로직 수정]
  List<Map<String, dynamic>> _getSmartContactItems(Map<String, dynamic> d) {
    List<Map<String, dynamic>> items = [];
    
    final phone = _getString(d, 'phone');
    final email = _getString(d, 'email');
    final website = _getString(d, 'website');
    final address = _getString(d, 'address');
    final instagram = _getString(d, 'instagram');
    final kakao = _getString(d, 'kakaoId') ?? _getString(d, 'kakao');
    final birthdate = _getString(d, 'birthdate');

    if (modeIndex == 0) { // Business
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.mail_outline, 'value': email, 'url': "mailto:$email"});
      if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website});
    
    } else if (modeIndex == 1) { // Social
      if (birthdate != null) items.add({'icon': Icons.cake, 'value': birthdate, 'url': null});
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
    
    } else { // Private
      if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.mail_outline, 'value': email, 'url': "mailto:$email"});
      if (address != null) items.add({'icon': Icons.home_outlined, 'value': address, 'url': null});
    }

    return items;
  }

  Widget _buildContactRow(Map<String, dynamic> item, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item['icon'], size: 14, color: color.withOpacity(0.6)),
            const SizedBox(width: 10),
            Flexible(child: Text(item['value'], style: GoogleFonts.nanumGothic(fontSize: 12, color: color, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
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