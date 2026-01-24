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
    // 1. 데이터 평탄화
    final Map<String, dynamic> safeData = _flattenData(data);

    final name = _getString(safeData, 'name') ?? 'NAME';
    
    // 2. 스마트 자막
    String? subtitle = _getString(safeData, 'role');
    if (subtitle == null && _getString(safeData, 'mbti') != null) {
      subtitle = _getString(safeData, 'mbti')?.toUpperCase();
    }
    subtitle ??= "CONTACT";

    String? logoUrl = _getString(safeData, 'logoUrl');
    
    // 3. 스마트 리스트
    List<Map<String, dynamic>> contactItems = _getSmartContactItems(safeData);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F0), // 베이지색 배경
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.notoSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2D2D2D))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.notoSans(fontSize: 14, color: const Color(0xFF888888), fontWeight: FontWeight.w500)),
                ],
              ),
              if (logoUrl != null)
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover),
                  ),
                )
              else
                Icon(
                  (safeData['instagram'] != null || safeData['mbti'] != null) ? Icons.sentiment_satisfied : Icons.circle, 
                  size: 40, 
                  color: Colors.grey[300]
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE0E0E0), thickness: 1),
          const SizedBox(height: 16),
          ...contactItems.map((item) => _buildContactRow(item)).toList(),
        ],
      ),
    );
  }

  // [스마트 데이터 추출 로직] (다른 카드와 동일한 로직)
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
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (email != null) items.add({'icon': Icons.email_outlined, 'value': email, 'url': "mailto:$email"});
      if (website != null) items.add({'icon': Icons.language, 'value': _shortenUrl(website), 'url': website});
      if (items.isEmpty) { // Fallback
         if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
         if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      }
    } 
    // Social
    else if (modeIndex == 1) {
      if (instagram != null) items.add({'icon': FontAwesomeIcons.instagram, 'value': "@$instagram", 'url': "https://instagram.com/$instagram"});
      if (kakao != null) items.add({'icon': FontAwesomeIcons.solidComment, 'value': kakao, 'url': "kakaotalk://"});
      if (birthdate != null) items.add({'icon': Icons.cake, 'value': birthdate, 'url': null});
      if (items.isEmpty && phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
    } 
    // Private
    else {
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
      if (address != null) items.add({'icon': Icons.home, 'value': address, 'url': null});
      if (items.isEmpty && email != null) items.add({'icon': Icons.email, 'value': email, 'url': "mailto:$email"});
    }

    if (items.isEmpty) {
      if (phone != null) items.add({'icon': Icons.phone, 'value': phone, 'url': "tel:$phone"});
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
            Icon(item['icon'], size: 16, color: const Color(0xFF888888)),
            const SizedBox(width: 12),
            Expanded(child: Text(item['value'], style: GoogleFonts.notoSans(fontSize: 14, color: const Color(0xFF2D2D2D)), maxLines: 1, overflow: TextOverflow.ellipsis)),
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