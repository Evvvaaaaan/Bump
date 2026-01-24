import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NeoBrutalismCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;

  const NeoBrutalismCard({
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
    subtitle ??= "HELLO WORLD";
    final logoUrl = _getString(safeData, 'logoUrl');
    final contactItems = _getSmartContactItems(safeData);

    final bgColor = modeIndex == 1 ? const Color(0xFFFFF475) : const Color(0xFFF4F4F0);
    const textColor = Colors.black;
    const borderColor = Colors.black;

    return AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: const [BoxShadow(color: borderColor, offset: Offset(8, 8), blurRadius: 0)],
        ),
        child: Stack(
          children: [
            Positioned(bottom: 80, left: 0, right: 0, child: Container(height: 3, color: borderColor)),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [상단 고정] 자막/로고
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(subtitle, style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w700, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 12),
                      if (logoUrl != null)
                        Container(width: 40, height: 40, decoration: BoxDecoration(border: Border.all(width: 2), image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)))
                      else
                        Icon(modeIndex == 1 ? Icons.tag_faces : Icons.gavel, color: textColor, size: 32),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // [중간 고정] 이름
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(name.toUpperCase(), style: GoogleFonts.archivoBlack(fontSize: 36, color: textColor, letterSpacing: -1)),
                  ),
                  
                  const SizedBox(height: 28),

                  // [하단 유동] 연락처 리스트 (Expanded + SingleChildScrollView)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: contactItems.isNotEmpty
                          ? contactItems.map((item) => _buildContactRow(item, textColor)).toList()
                          : [Text("NO CONTACT INFO", style: GoogleFonts.spaceMono(color: textColor, fontSize: 12, fontWeight: FontWeight.bold))],
                      ),
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

  // [필수 헬퍼 함수들]
  List<Map<String, dynamic>> _getSmartContactItems(Map<String, dynamic> d) {
    List<Map<String, dynamic>> items = [];
    final phone = _getString(d, 'phone'); final email = _getString(d, 'email'); final website = _getString(d, 'website'); final company = _getString(d, 'company');
    final instagram = _getString(d, 'instagram'); final kakao = _getString(d, 'kakaoId') ?? _getString(d, 'kakao'); final birthdate = _getString(d, 'birthdate'); final address = _getString(d, 'address');

    if (modeIndex == 0) { if (company != null) items.add({'icon': Icons.business, 'value': company, 'url': null}); if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"}); if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website}); if (items.isEmpty) { if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"}); if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"}); }} else if (modeIndex == 1) { if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"}); if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"}); if (birthdate != null) items.add({'icon': Icons.cake_outlined, 'value': birthdate, 'url': null}); if (items.isEmpty && phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); } else { if (phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"}); if (address != null) items.add({'icon': Icons.home_outlined, 'value': address, 'url': null}); if (items.isEmpty && email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"}); }
    if (items.isEmpty && phone != null) items.add({'icon': Icons.phone_iphone, 'value': phone, 'url': "tel:$phone"});
    return items;
  }

  Widget _buildContactRow(Map<String, dynamic> item, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: GestureDetector(
        onTap: () => item['url'] != null ? _launch(item['url']) : null,
        child: Row(
          children: [
            Icon(item['icon'], size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item['value'], 
                style: GoogleFonts.spaceMono(fontSize: 12, color: color, fontWeight: FontWeight.w700), 
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