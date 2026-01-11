import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart'; // 연락처 패키지
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

  // [수정됨] 스마트 링크 및 상세 연락처 저장 함수
  Future<void> _launchSmartLink(BuildContext context, String input, {String type = 'web'}) async {
    if (input.isEmpty) return;
    String urlString = input.trim();

    try {
      // 1. [핵심] 전화번호인 경우 -> 상세 정보(이름, 직함, 회사)를 포함하여 저장 화면 이동
      if (type == 'contact' && RegExp(r'^[0-9-]+$').hasMatch(urlString)) {
        try {
          // 데이터 가져오기
          final String firstName = data['name'] ?? "";
          // [요청사항 반영] LastName(성) 필드에 '직함'을 넣습니다.
          final String lastName = data['role'] ?? ""; 
          final String company = data['company'] ?? "";
          final String email = data['email'] ?? "";
          
          // 연락처 객체 생성
          final newContact = Contact()
            ..name.first = firstName
            ..name.last = lastName // 요청하신대로 직함을 '성'에 입력
            ..phones = [Phone(urlString)];

          // 회사 정보 추가
          if (company.isNotEmpty) {
            newContact.organizations = [
              Organization(
                company: company,
                // title: lastName, // (옵션) 직함 필드에도 직함을 넣어줍니다.
              )
            ];
          }

          // 이메일이 있다면 추가
          if (email.isNotEmpty) {
            newContact.emails = [Email(email)];
          }
            
          // 기기의 '연락처 추가' 화면 띄우기 (입력된 정보가 채워진 상태로 열림)
          await FlutterContacts.openExternalInsert(newContact);
          return;
        } catch (e) {
          print("연락처 저장 실패: $e");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("연락처 앱을 열 수 없습니다.")),
            );
          }
          return;
        }
      }

      // 2. 나머지 링크 처리 (SNS, 음악 등 기존 로직 유지)
      Uri? uri;
      
      if (type == 'music') {
        if (!urlString.startsWith('http')) {
          urlString = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(urlString)}';
        }
      } else if (type == 'sns') {
        if (urlString.startsWith('@')) {
          urlString = 'https://www.instagram.com/${urlString.replaceAll('@', '')}';
        } else if (!urlString.startsWith('http') && !urlString.contains('.')) {
          urlString = 'https://www.instagram.com/$urlString';
        } else if (!urlString.startsWith('http')) {
           urlString = 'https://$urlString'; 
        }
      } else if (type == 'contact') {
        // 이메일 클릭 시
        if (urlString.contains('@')) {
          uri = Uri(scheme: 'mailto', path: urlString);
        }
      }

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
    final modeLabel = ['Business', 'Social', 'Private'][modeIndex];
    
    // UI 표시용 데이터 준비
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 프로필 영역
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                  image: photoUrl != null
                      ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                      : null,
                  color: Colors.grey.withValues(alpha: 0.3),
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
                          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5)),
                ),
                child: Text(modeLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor.withValues(alpha: 0.9))),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),

          // Social Mode 표시
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("#$tag", style: const TextStyle(fontSize: 12, color: Colors.white)),
                  )).toList(),
                ),
              ),

            Row(
              children: [
                if (music != null && music.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchSmartLink(context, music, type: 'music'),
                      child: _buildIconText(Icons.music_note, music, isLink: true),
                    ),
                  ),
                if (birthday != null && birthday.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  _buildIconText(Icons.cake, birthday),
                ],
              ],
            ),
            
            if (contact.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _launchSmartLink(context, contact, type: 'sns'),
                child: _buildIconText(Icons.link, contact, isLink: true),
              ),
            ]

          ] else ...[
            // Business & Private 표시
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
        Icon(icon, size: 16, color: isLink ? Colors.blueAccent.shade100 : Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text, 
            style: TextStyle(
              fontSize: 14, 
              color: isLink ? Colors.blueAccent.shade100 : Colors.white.withValues(alpha: 0.8),
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