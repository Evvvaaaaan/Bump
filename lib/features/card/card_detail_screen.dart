import 'package:bump/features/common/card_renderer.dart'; 
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
    // [1] 데이터 병합
    final Map<String, dynamic> finalData = _flattenData(cardData);

    // [2] 모드 확인
    final int modeIndex = int.tryParse(finalData['modeIndex']?.toString() ?? '0') ?? 0;

    // [3] 정보 추출
    final String? phone = _findValue(finalData, ['phone', 'mobile', 'hp']);
    final String? email = _findValue(finalData, ['email', 'mail']);
    final String? mbti = _findValue(finalData, ['mbti', 'MBTI']);
    final String? birthdate = _findValue(finalData, ['birthdate', 'birthday', 'birth']);
    final String? address = _findValue(finalData, ['address', 'addr']);
    
    // [4] 소셜 링크 통합 수집
    final Map<String, String> socialLinks = _collectLinks(finalData);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("명함 상세", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // 명함 디자인 렌더링
            Hero(
              tag: 'card_hero', 
              child: CardRenderer(
                data: finalData,
                modeIndex: modeIndex,
              ),
            ),

            const SizedBox(height: 40),
            
            // [수정됨] context를 인자로 함께 전달합니다.
            _buildActionButtons(context, phone, email, socialLinks),

            const SizedBox(height: 30),

            // 텍스트 상세 정보 표시 영역
            if (mbti != null || birthdate != null || address != null || socialLinks.containsKey('kakao'))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Text("PROFILE INFO", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // [수정됨] context 전달
                    if (mbti != null) _buildInfoRow(context, Icons.psychology, "MBTI", mbti),
                    if (birthdate != null) _buildInfoRow(context, Icons.cake, "생일", birthdate),
                    if (address != null) _buildInfoRow(context, Icons.location_on, "주소", address, isCopyable: true),
                    
                    if (socialLinks.containsKey('kakao')) 
                      _buildInfoRow(context, FontAwesomeIcons.comment, "카카오톡 ID", socialLinks['kakao']!, isCopyable: true),
                  ],
                ),
              ),
              
            const SizedBox(height: 40),
            
            // 삭제 버튼
            
          ],
        ),
      ),
    );
  }

  // --- [데이터 처리 로직] ---

  Map<String, dynamic> _flattenData(Map<String, dynamic> source) {
    Map<String, dynamic> result = Map.from(source);
    if (source['profile'] != null && source['profile'] is Map) {
      result.addAll(Map<String, dynamic>.from(source['profile']));
    }
    if (source['targetProfileData'] != null && source['targetProfileData'] is Map) {
       result.addAll(Map<String, dynamic>.from(source['targetProfileData']));
    }
    return result;
  }

  String? _findValue(Map<String, dynamic> data, List<String> keys) {
    for (var key in keys) {
      if (data.containsKey(key) && data[key].toString().isNotEmpty) {
        return data[key].toString();
      }
      for (var entry in data.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase() && entry.value.toString().isNotEmpty) {
           return entry.value.toString();
        }
      }
    }
    return null;
  }

  Map<String, String> _collectLinks(Map<String, dynamic> data) {
    final Map<String, String> links = {};
    if (data['links'] != null && data['links'] is Map) {
      final map = Map<String, dynamic>.from(data['links']);
      map.forEach((k, v) {
        if(v != null && v.toString().isNotEmpty) {
          links[k.toString().toLowerCase()] = v.toString();
        }
      });
    }
    void check(String standardKey, List<String> candidates) {
      if (!links.containsKey(standardKey)) {
        final val = _findValue(data, candidates);
        if (val != null) links[standardKey] = val;
      }
    }
    check('instagram', ['instagram', 'insta']);
    check('kakao', ['kakao', 'kakaoId', 'kakaotalk', 'kakao_id']);
    check('youtube', ['youtube', 'yt']);
    check('website', ['website', 'web', 'blog', 'homepage']);
    check('tiktok', ['tiktok']);
    check('twitter', ['twitter', 'x']);
    check('facebook', ['facebook', 'fb']);
    return links;
  }

  // --- [UI 빌더] ---

  // [수정됨] BuildContext context 인자 추가
  Widget _buildActionButtons(BuildContext context, String? phone, String? email, Map<String, String> links) {
    List<Widget> buttons = [];

    if (phone != null) {
      buttons.add(_buildActionButton(Icons.phone, "전화", Colors.green, () => _launchUri('tel:$phone')));
      buttons.add(_buildActionButton(Icons.message, "문자", Colors.lightGreen, () => _launchUri('sms:$phone')));
    }
    if (email != null) {
      buttons.add(_buildActionButton(Icons.email, "이메일", Colors.blueGrey, () => _launchUri('mailto:$email')));
    }

    links.forEach((key, value) {
      switch (key) {
        case 'instagram':
          buttons.add(_buildActionButton(FontAwesomeIcons.instagram, "Instagram"
          , const Color(0xFFE1306C), () {
            final id = value.replaceAll('@', '').trim();
            _launchUri('https://instagram.com/$id');
          }));
          break;
        case 'kakao':
          buttons.add(_buildActionButton(FontAwesomeIcons.solidComment, "KakaoTalk", const Color(0xFFFFE812), () {
            Clipboard.setData(ClipboardData(text: value));
            // 이제 context를 사용할 수 있습니다.
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("카카오톡 ID가 복사되었습니다.")));
            _launchUri('kakaotalk://');
          }, textColor: Colors.white70)); 
          break;
        case 'youtube':
          buttons.add(_buildActionButton(FontAwesomeIcons.youtube, "YouTube", const Color(0xFFFF0000), () => _launchUri(value)));
          break;
        case 'website':
          buttons.add(_buildActionButton(Icons.language, "Web", Colors.blueAccent, () => _launchUri(value)));
          break;
        case 'tiktok':
          buttons.add(_buildActionButton(FontAwesomeIcons.tiktok, "TikTok", Colors.white, () => _launchUri(value)));
          break;
        case 'twitter':
          buttons.add(_buildActionButton(FontAwesomeIcons.xTwitter, "X", Colors.white, () => _launchUri(value)));
          break;
        case 'facebook':
          buttons.add(_buildActionButton(FontAwesomeIcons.facebook, "Facebook", const Color(0xFF1877F2), () => _launchUri(value)));
          break;
      }
    });

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 20, 
      runSpacing: 20, 
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap, {Color textColor = Colors.white70}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Icon(icon, color: color == const Color(0xFFFFE812) ? Colors.black : Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // [수정됨] BuildContext context 인자 추가
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: Colors.white70),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500), textAlign: TextAlign.end),
          ),
          if (isCopyable) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  // 전달받은 context 사용
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label 복사됨"), duration: const Duration(seconds: 1)));
              },
              child: const Icon(Icons.copy, size: 16, color: Color(0xFF4B6EFF)),
            ),
          ]
        ],
      ),
    );
  }

  Future<void> _launchUri(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http') && !url.startsWith('tel') && !url.startsWith('mailto') && !url.startsWith('sms') && !url.startsWith('kakaotalk')) {
      finalUrl = 'https://$url';
    }
    try { 
      final uri = Uri.parse(finalUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication); 
    } catch (e) {
      debugPrint("링크 실행 실패: $e");
    }
  }
}