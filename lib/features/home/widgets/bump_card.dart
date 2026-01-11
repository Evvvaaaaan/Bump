import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BumpCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex; // 0: Business, 1: Social, 2: Private
  final Color primaryColor;

  const BumpCard({
    super.key,
    required this.data,
    required this.modeIndex,
    required this.primaryColor,
  });

  // [수정됨] 스마트 링크 연결 함수
  Future<void> _launchSmartLink(BuildContext context, String input, {String type = 'web'}) async {
    if (input.isEmpty) return;

    String urlString = input.trim(); // 공백 제거
    Uri? uri;

    try {
      if (type == 'music') {
        // 음악: 링크가 아니면 유튜브 검색
        if (!urlString.startsWith('http')) {
          urlString = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(urlString)}';
        }
      } else if (type == 'sns') {
        // [수정 로직]
        // 1. '@'로 시작하면 인스타그램
        if (urlString.startsWith('@')) {
          urlString = 'https://www.instagram.com/${urlString.replaceAll('@', '')}';
        } 
        // 2. 'http'도 없고 '점(.)'도 없으면 순수 ID로 간주 -> 인스타그램 연결
        // (예: "evan" -> "https://instagram.com/evan")
        else if (!urlString.startsWith('http') && !urlString.contains('.')) {
          urlString = 'https://www.instagram.com/$urlString';
        } 
        // 3. 그 외(도메인 형식 등)는 https만 붙여줌 (예: "twitter.com/user" -> "https://twitter.com/user")
        else if (!urlString.startsWith('http')) {
           urlString = 'https://$urlString'; 
        }
      } else if (type == 'contact') {
        // 전화/이메일 처리
        if (urlString.contains('@') && !urlString.startsWith('http')) {
          uri = Uri(scheme: 'mailto', path: urlString);
        } else if (RegExp(r'^[0-9-]+$').hasMatch(urlString)) {
          uri = Uri(scheme: 'tel', path: urlString);
        }
      }

      // 최종 URL 파싱
      uri ??= Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("연결할 수 없습니다: $urlString")),
          );
        }
      }
    } catch (e) {
      print("링크 열기 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (아래 build 메서드는 기존과 동일하므로 그대로 두셔도 됩니다)
    final modeLabel = ['Business', 'Social', 'Private'][modeIndex];
    
    // 데이터 가져오기
    final name = data['name'] ?? "Guest";
    final photoUrl = data['photoUrl'];
    
    final subtitle = data['role'] ?? data['bio'] ?? "No description";
    final detail = data['company'] ?? data['location'] ?? "";
    final contact = data['phone'] ?? data['email'] ?? data['instagram'] ?? "";

    final String? mbti = data['mbti'];
    final String? music = data['music'];
    final String? birthday = data['birthday'];
    final List<dynamic> hobbies = data['hobbies'] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 프로필
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  image: photoUrl != null
                      ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                      : null,
                  color: Colors.grey.withOpacity(0.3),
                ),
                child: photoUrl == null
                    ? const Icon(Icons.person, color: Colors.white70, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    if (modeIndex == 1 && mbti != null && mbti.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(mbti, 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                      )
                    else
                      Text(subtitle,
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                ),
                child: Text(modeLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor.withOpacity(0.9))),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),

          // Social Mode 내용
          if (modeIndex == 1) ...[
            if (subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('"$subtitle"', 
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white)
                ),
              ),
            
            if (hobbies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: hobbies.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("#$tag", style: const TextStyle(fontSize: 12, color: Colors.white)),
                  )).toList(),
                ),
              ),

            // 음악 & 생일
            Row(
              children: [
                if (music != null && music.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchSmartLink(context, music!, type: 'music'),
                      child: _buildIconText(Icons.music_note, music!, isLink: true),
                    ),
                  ),
                if (birthday != null && birthday.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _buildIconText(Icons.cake, birthday),
                ],
              ],
            ),
            
            // SNS (Instagram)
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _launchSmartLink(context, contact, type: 'sns'),
                child: _buildIconText(Icons.link, contact, isLink: true),
              ),
            ]

          ] else ...[
            // Business & Private
            _buildIconText(Icons.business, detail.isEmpty ? "No details" : detail),
            
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _launchSmartLink(context, contact, type: 'contact'),
                child: _buildIconText(contact.contains('@') ? Icons.email : Icons.phone, contact, isLink: true),
              ),
            ]
          ],
        ],
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text, {bool isLink = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: isLink ? Colors.blueAccent.shade100 : Colors.white.withOpacity(0.6)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text, 
            style: TextStyle(
              fontSize: 14, 
              color: isLink ? Colors.blueAccent.shade100 : Colors.white.withOpacity(0.8),
              decoration: isLink ? TextDecoration.underline : TextDecoration.none,
              decorationColor: Colors.blueAccent.shade100,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}