import 'package:bump/features/common/card_renderer.dart'; // [필수] CardRenderer 임포트
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

class CardDetailScreen extends StatelessWidget {
  final Map<String, dynamic> cardData;

  const CardDetailScreen({super.key, required this.cardData});

  @override
  Widget build(BuildContext context) {
    // [핵심 1] 데이터 병합 로직 (Data Flattening)
    // DB 구조가 { profile: { name: "...", mbti: "..." } } 일 경우를 대비해
    // 안쪽 데이터를 바깥으로 끄집어냅니다.
    final Map<String, dynamic> finalData = _flattenData(cardData);

    // [디버깅용 로그] 터미널에서 데이터가 제대로 들어오는지 확인 가능
    print("📌 상세 화면 최종 데이터: $finalData");

    // [2] 모드 확인 (0: Business, 1: Social, 2: Private)
    final int modeIndex = int.tryParse(finalData['modeIndex']?.toString() ?? '0') ?? 0;

    // [3] 연락처 정보 추출 (버튼용)
    final String? phone = _getString(finalData, 'phone');
    final String? email = _getString(finalData, 'email');
    final String? instagram = _getString(finalData, 'instagram');
    // 카카오톡은 kakaoId 또는 kakao 키값 둘 다 확인
    final String? kakao = _getString(finalData, 'kakaoId') ?? _getString(finalData, 'kakao'); 
    final String? website = _getString(finalData, 'website');
    final String? address = _getString(finalData, 'address');
    final String? mbti = _getString(finalData, 'mbti');
    final String? birthdate = _getString(finalData, 'birthdate');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("명함 상세", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // [핵심 2] 명함 디자인 렌더링
            // 병합된 finalData를 넘기므로 CardRenderer가 'theme'와 'mbti'를 모두 찾을 수 있음
            Hero(
              tag: 'card_hero', 
              child: CardRenderer(
                data: finalData,
                modeIndex: modeIndex,
              ),
            ),

            const SizedBox(height: 40),
            
            // [핵심 3] 하단 액션 버튼 (모드 통합 표시)
            _buildButtonGrid([
               if (phone != null) _buildActionButton(Icons.phone, "전화", () => _launchUri('tel:$phone')),
               if (phone != null) _buildActionButton(Icons.message, "문자", () => _launchUri('sms:$phone')),
               if (email != null) _buildActionButton(Icons.email, "이메일", () => _launchUri('mailto:$email')),
               if (instagram != null) _buildActionButton(FontAwesomeIcons.instagram, "Instagram", () => _launchUri('https://instagram.com/$instagram')),
               if (kakao != null) _buildActionButton(FontAwesomeIcons.solidComment, "KakaoTalk", () => _launchUri('kakaotalk://')),
               if (website != null) _buildActionButton(Icons.language, "웹사이트", () => _launchUri(website)),
            ]),

            const SizedBox(height: 30),

            // [핵심 4] 텍스트 상세 정보 (MBTI, 생일 등)
            if (mbti != null || birthdate != null || address != null || kakao != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("상세 정보", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (mbti != null) _buildInfoRow(Icons.psychology, "MBTI", mbti),
                    if (birthdate != null) _buildInfoRow(Icons.cake, "생일", birthdate),
                    if (kakao != null) _buildInfoRow(FontAwesomeIcons.comment, "카카오톡 ID", kakao, isCopyable: true),
                    if (address != null) _buildInfoRow(Icons.location_on, "주소", address, isCopyable: true),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // [데이터 평탄화 함수]
  // profile 껍질을 벗겨서 알맹이를 밖으로 꺼냅니다.
  Map<String, dynamic> _flattenData(Map<String, dynamic> source) {
    Map<String, dynamic> result = Map.from(source);
    
    // profile 키가 있고 그 안에 데이터가 있다면
    if (source['profile'] != null && source['profile'] is Map) {
      final profileMap = Map<String, dynamic>.from(source['profile']);
      
      // profile 안의 모든 데이터를 최상위로 복사 (덮어쓰기)
      result.addAll(profileMap);

      // 특히 theme 정보가 안쪽에 있다면 확실하게 꺼냄
      if (profileMap['theme'] != null) {
        result['theme'] = profileMap['theme'];
      }
    }
    return result;
  }

  String? _getString(Map<String, dynamic> data, String key) {
    final val = data[key];
    if (val == null || val.toString().trim().isEmpty) return null;
    return val.toString();
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.end),
          ),
          if (isCopyable) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Clipboard.setData(ClipboardData(text: value)),
              child: const Icon(Icons.copy, size: 14, color: Colors.blueAccent),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildButtonGrid(List<Widget> buttons) {
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
      children: buttons,
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _launchUri(String url) async {
    final uri = Uri.parse(url.startsWith('http') || url.startsWith('tel') || url.startsWith('mailto') || url.startsWith('sms') || url.startsWith('kakaotalk') ? url : 'https://$url');
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }
}