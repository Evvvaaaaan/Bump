import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AuroraGradientCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;

  const AuroraGradientCard({
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
    subtitle ??= "CREATIVE SOUL";
    final logoUrl = _getString(safeData, 'logoUrl');
    final contactItems = _getSmartContactItems(safeData);

    return AspectRatio(
      aspectRatio: 1.586, // 신용카드 표준 비율
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4158D0), Color(0xFFC850C0), Color(0xFFFFCC70)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC850C0).withOpacity(0.4), 
              blurRadius: 20, 
              offset: const Offset(0, 8)
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // 배경 데코레이션
              Positioned(
                bottom: -50, left: -20, 
                child: Icon(Icons.waves, size: 200, color: Colors.white.withOpacity(0.1))
              ),
              
              Padding(
                padding: const EdgeInsets.all(26.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [상단 고정] 로고 및 자막
                    Row(
                      children: [
                        if (logoUrl != null)
                          CircleAvatar(backgroundImage: NetworkImage(logoUrl), radius: 18, backgroundColor: Colors.white24)
                        else
                          Icon(modeIndex == 1 ? Icons.auto_awesome : Icons.bolt, color: Colors.white, size: 30),
                        const SizedBox(width: 12),
                        // 텍스트가 길어지면 ... 처리 (가로 오버플로우 방지)
                        Expanded(
                          child: Text(
                            subtitle, 
                            style: GoogleFonts.righteous(color: Colors.white.withOpacity(0.8), fontSize: 14, letterSpacing: 1.0), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // [중간 고정] 이름 (FittedBox로 자동 크기 조절)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name, 
                        style: GoogleFonts.righteous(
                          fontSize: 34, 
                          color: Colors.white, 
                          shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: const Offset(2, 2))]
                        )
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // [하단 유동] 연락처 리스트 (Expanded + SingleChildScrollView로 세로 오버플로우 완벽 방지)
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
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
            ],
          ),
        ),
      ),
    );
  }
  
  // [필수 헬퍼 함수들]
  List<Map<String, dynamic>> _getSmartContactItems(Map<String, dynamic> d) {
    List<Map<String, dynamic>> items = [];
    final phone = _getString(d, 'phone'); final email = _getString(d, 'email'); final website = _getString(d, 'website'); final company = _getString(d, 'company');
    final instagram = _getString(d, 'instagram'); final kakao = _getString(d, 'kakaoId') ?? _getString(d, 'kakao'); final birthdate = _getString(d, 'birthdate'); final address = _getString(d, 'address');
    
    if (modeIndex == 0) { if (company != null) items.add({'icon': Icons.business, 'value': company, 'url': null}); if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"}); if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website}); if (items.isEmpty) { if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"}); if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"}); }} else if (modeIndex == 1) { if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"}); if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"}); if (birthdate != null) items.add({'icon': Icons.cake_outlined, 'value': birthdate, 'url': null}); if (items.isEmpty && phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); } else { if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); if (address != null) items.add({'icon': Icons.home_outlined, 'value': address, 'url': null}); if (items.isEmpty && email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"}); }
    if (items.isEmpty && phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
    return items;
  }

  Widget _buildContactRow(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Row(
          children: [
            Icon(item['icon'], size: 16, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item['value'], 
                style: GoogleFonts.righteous(fontSize: 13, color: Colors.white.withOpacity(0.9)), 
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