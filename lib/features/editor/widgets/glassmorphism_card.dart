import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GlassmorphismCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;

  const GlassmorphismCard({
    super.key,
    required this.data,
    required this.modeIndex,
  });

  @override
  Widget build(BuildContext context) {
    final safeData = _flattenData(data);
    final name = _getString(safeData, 'name') ?? 'NAME';
    String? subtitle = _getString(safeData, 'role');
    if (subtitle == null && _getString(safeData, 'mbti') != null) {
      subtitle = _getString(safeData, 'mbti')?.toUpperCase();
    }
    subtitle ??= "DIGITAL CONTACT";
    final logoUrl = _getString(safeData, 'logoUrl');
    final contactItems = _getSmartContactItems(safeData);

    return AspectRatio(
      aspectRatio: 1.586,
      child: Stack(
        children: [
          // 1. 배경 레이어
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF121212),
            ),
            child: Stack(
              children: [
                Positioned(top: -50, left: -50, child: _buildBlob(const Color(0xFFFF6B6B))),
                Positioned(bottom: -80, right: -20, child: _buildBlob(const Color(0xFF4ECDC4))),
                Positioned(top: 80, right: -80, child: _buildBlob(const Color(0xFFC7F464))),
              ],
            ),
          ),

          // 2. 유리 효과 및 콘텐츠 레이어
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]
                  )
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [상단 고정 영역] 로고 및 자막
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         if (logoUrl != null)
                          CircleAvatar(backgroundImage: NetworkImage(logoUrl), radius: 20, backgroundColor: Colors.white10)
                        else
                          Icon(modeIndex == 1 ? Icons.bubble_chart : Icons.layers, color: Colors.white70, size: 36),
                        const SizedBox(width: 12),
                        Expanded( // 자막이 길어지면 잘리도록
                          child: Text(subtitle, style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20), // 간격

                    // [중간 고정 영역] 이름
                    FittedBox( // 이름이 너무 길면 폰트 크기를 줄임
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(name, style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    
                    const SizedBox(height: 20), // 간격

                    // [하단 유동 영역] 연락처 리스트 (핵심 수정: Expanded + SingleChildScrollView)
                    Expanded( 
                      child: SingleChildScrollView( // 내용이 넘치면 스크롤
                        physics: const BouncingScrollPhysics(), // 부드러운 스크롤 효과
                        child: Column(
                          children: contactItems.isNotEmpty
                            ? contactItems.map((item) => _buildContactRow(item)).toList()
                            : [const Text("연락처 정보 없음", style: TextStyle(color: Colors.white38, fontSize: 12))],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (나머지 _buildBlob, _getSmartContactItems 등 하단 함수들은 기존과 동일)
  Widget _buildBlob(Color color) { return Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.5), boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 80, spreadRadius: 20)])); }
  List<Map<String, dynamic>> _getSmartContactItems(Map<String, dynamic> d) { List<Map<String, dynamic>> items = []; final phone = _getString(d, 'phone'); final email = _getString(d, 'email'); final website = _getString(d, 'website'); final company = _getString(d, 'company'); final instagram = _getString(d, 'instagram'); final kakao = _getString(d, 'kakaoId') ?? _getString(d, 'kakao'); final birthdate = _getString(d, 'birthdate'); final address = _getString(d, 'address'); if (modeIndex == 0) { if (company != null) items.add({'icon': Icons.business, 'value': company, 'url': null}); if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"}); if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website}); if (items.isEmpty) { if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"}); if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"}); }} else if (modeIndex == 1) { if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"}); if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"}); if (birthdate != null) items.add({'icon': Icons.cake_outlined, 'value': birthdate, 'url': null}); if (items.isEmpty && phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); } else { if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); if (address != null) items.add({'icon': Icons.home_outlined, 'value': address, 'url': null}); if (items.isEmpty && email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"}); } if (items.isEmpty && phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); return items; } // take(3) 제거 (스크롤 되므로 다 보여줌)
  Widget _buildContactRow(Map<String, dynamic> item) { return Padding(padding: const EdgeInsets.only(bottom: 8.0), child: GestureDetector(onTap: () => item['url'] != null ? _launch(item['url']) : null, child: Row(children: [Icon(item['icon'], size: 14, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(item['value'], style: GoogleFonts.outfit(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis))]))); }
  Map<String, dynamic> _flattenData(Map<String, dynamic> source) { Map<String, dynamic> result = Map.from(source); if (source['profile'] != null && source['profile'] is Map) { result.addAll(Map<String, dynamic>.from(source['profile'])); } return result; }
  String? _getString(Map<String, dynamic> d, String key) { final val = d[key]; if (val == null || val.toString().trim().isEmpty) return null; return val.toString(); }
  String _shortenUrl(String url) => url.replaceFirst(RegExp(r'https?://(www\.)?'), '');
  Future<void> _launch(String url) async { final uri = Uri.parse(url.startsWith('http') || url.startsWith('tel') || url.startsWith('mailto') || url.startsWith('kakaotalk') ? url : 'https://$url'); if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); }
}