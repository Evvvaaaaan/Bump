import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // [필수] 링크 이동용

class BumpMatchDialog extends StatelessWidget {
  final Map<String, dynamic> partnerData;
  final VoidCallback onConfirm;

  const BumpMatchDialog({
    super.key,
    required this.partnerData,
    required this.onConfirm,
  });

  // 링크 실행 함수
  Future<void> _launchLink(String type, String value) async {
    Uri uri;
    
    switch (type) {
      case 'phone':
      case 'mobile':
        uri = Uri.parse("tel:$value");
        break;
      case 'email':
        uri = Uri.parse("mailto:$value");
        break;
      case 'instagram':
        // 인스타그램 앱 열기 시도, 없으면 웹으로
        // ID만 저장된 경우를 가정 (예: vmfhrmfoald36)
        final cleanId = value.replaceAll('@', '').trim();
        uri = Uri.parse("https://instagram.com/$cleanId");
        break;
      case 'kakao':
        // 카카오톡 오픈채팅 혹은 ID 검색 (여기서는 웹 검색 예시)
        uri = Uri.parse("https://open.kakao.com/o/$value"); 
        // 또는 실제 ID라면 클립보드 복사 로직을 넣을 수도 있습니다.
        break;
      case 'web':
      case 'blog':
        if (!value.startsWith('http')) {
          uri = Uri.parse("https://$value");
        } else {
          uri = Uri.parse(value);
        }
        break;
      default:
        return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint("링크를 열 수 없습니다: $uri");
      }
    } catch (e) {
      debugPrint("링크 실행 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 데이터 안전하게 가져오기
    final name = partnerData['name'] ?? 'Unknown';
    final role = partnerData['role'] ?? 'No Role';
    final company = partnerData['company'] ?? '';
    final photoUrl = partnerData['photoUrl']; // 이미지 URL (없으면 null)
    
    // 2. 링크 정보 가져오기 (여기가 문제였을 것입니다)
    // 데이터 구조에 따라 'links' 또는 'social_media' 일 수 있습니다. 확인 필요.
    final Map<String, dynamic> links = partnerData['links'] is Map 
        ? Map<String, dynamic>.from(partnerData['links']) 
        : {};

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 프로필 사진 ---
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4B6EFF), width: 3),
                image: photoUrl != null
                    ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                    : null,
                color: Colors.grey[800],
              ),
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white54)
                  : null,
            ),
            const SizedBox(height: 20),

            // --- 이름 및 역할 ---
            Text(
              name,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "$role ${company.isNotEmpty ? ' @ $company' : ''}",
              style: GoogleFonts.notoSans(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 24),
            
            // --- [핵심 수정] 소셜 아이콘 리스트 ---
            if (links.isNotEmpty) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16, // 아이콘 간격
                runSpacing: 16,
                children: links.entries.map((entry) {
                  final key = entry.key.toLowerCase();
                  final value = entry.value.toString();
                  if (value.isEmpty) return const SizedBox.shrink();

                  return _buildSocialIcon(key, value);
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // --- 연결 버튼 ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B6EFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "명함 교환하기",
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 아이콘 빌더 함수
  Widget _buildSocialIcon(String type, String value) {
    IconData iconData;
    Color iconColor;
    
    // 타입에 따른 아이콘 및 색상 설정
    switch (type) {
      case 'instagram':
        iconData = Icons.camera_alt; // 인스타그램 (FontAwesome이 없다면 기본 아이콘 사용)
        iconColor = const Color(0xFFE1306C);
        break;
      case 'kakao':
        iconData = Icons.chat_bubble; // 카카오톡
        iconColor = const Color(0xFFFFE812);
        break;
      case 'phone':
      case 'mobile':
        iconData = Icons.phone;
        iconColor = Colors.greenAccent;
        break;
      case 'email':
        iconData = Icons.email;
        iconColor = Colors.blueAccent;
        break;
      case 'web':
      case 'blog':
        iconData = Icons.language;
        iconColor = Colors.cyanAccent;
        break;
      default:
        iconData = Icons.link;
        iconColor = Colors.white70;
    }

    return GestureDetector(
      onTap: () => _launchLink(type, value),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(iconData, color: iconColor, size: 22),
      ),
    );
  }
}