import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class BumpCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;
  final Color primaryColor;

  const BumpCard({
    super.key,
    required this.data,
    required this.modeIndex,
    required this.primaryColor,
  });

  Future<void> _launchSmartLink(BuildContext context, String input, {String type = 'web'}) async {
    if (input.isEmpty) return;
    String urlString = input.trim();
    try {
      if (type == 'contact' && RegExp(r'^[0-9-]+$').hasMatch(urlString)) {
        try {
          final String firstName = data['name'] ?? "";
          final String lastName = data['role'] ?? "";
          final String company = data['company'] ?? "";
          final String email = data['email'] ?? "";
          final newContact = Contact()
            ..name.first = firstName
            ..name.last = lastName
            ..phones = [Phone(urlString)];
          if (company.isNotEmpty) newContact.organizations = [Organization(company: company, title: lastName)];
          if (email.isNotEmpty) newContact.emails = [Email(email)];
          await FlutterContacts.openExternalInsert(newContact);
          return;
        } catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("연락처 앱을 열 수 없습니다.")));
          return;
        }
      }
      Uri? uri;
      if (type == 'music') {
        if (!urlString.startsWith('http')) urlString = 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(urlString)}';
      } else if (type == 'sns') {
        if (urlString.startsWith('@')) urlString = 'https://www.instagram.com/${urlString.replaceAll('@', '')}';
        else if (!urlString.startsWith('http') && !urlString.contains('.')) urlString = 'https://www.instagram.com/$urlString';
        else if (!urlString.startsWith('http')) urlString = 'https://$urlString';
      } else if (type == 'contact' && urlString.contains('@')) {
        uri = Uri(scheme: 'mailto', path: urlString);
      }
      uri ??= Uri.parse(urlString.startsWith('http') ? urlString : 'https://$urlString');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      else if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("연결할 수 없습니다: $urlString")));
    } catch (e) {
      print("링크 열기 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = ['Business', 'Social', 'Private'][modeIndex];
    
    // 스타일 데이터
    final Map<String, dynamic> style = data['style'] ?? {};
    final String colorType = style['colorType'] ?? 'gradient';
    final int colorId = style['colorId'] ?? 0;
    final String texture = style['texture'] ?? 'glass';

    // 색상 프리셋
    final List<Color> solidColors = [
      Colors.grey.shade800, const Color(0xFF1A237E), const Color(0xFF004D40),
      const Color(0xFFB71C1C), const Color(0xFF4A148C), Colors.black,
      const Color(0xFFE65100), const Color(0xFF3E2723), const Color(0xFF263238),
      const Color(0xFF880E4F), const Color(0xFF0D47A1),
    ];
    final List<List<Color>> gradientColors = [
      [const Color(0xFF434343), const Color(0xFF000000)],
      [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
      [const Color(0xFF614385), const Color(0xFF516395)],
      [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      [const Color(0xFFFF512F), const Color(0xFFDD2476)], // Sunset
      [const Color(0xFF11998e), const Color(0xFF38ef7d)], // Mint
      [const Color(0xFFC94B4B), const Color(0xFF4B134F)], // Cherry
      [const Color(0xFF00C9FF), const Color(0xFF92FE9D)], // Neon Green
      [const Color(0xFFFC466B), const Color(0xFF3F5EFB)], // Neon Blue
    ];

    BoxDecoration baseDecoration;
    if (colorType == 'solid') {
      final color = solidColors[colorId < solidColors.length ? colorId : 0];
      baseDecoration = BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      );
    } else {
      final colors = gradientColors[colorId < gradientColors.length ? colorId : 0];
      baseDecoration = BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      );
    }

    Widget? textureOverlay;
    if (texture == 'glass') {
      textureOverlay = ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
          ),
        ),
      );
    } else if (texture == 'metal') {
      textureOverlay = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.15), Colors.transparent, Colors.white.withOpacity(0.05)],
            stops: const [0.0, 0.5, 1.0],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.white.withOpacity(0.05), Colors.transparent],
              stops: const [0.0, 0.5, 1.0],
              tileMode: TileMode.repeated,
            ),
          ),
        ),
      );
    } else if (texture == 'carbon') {
      textureOverlay = ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          size: Size.infinite,
          painter: _StripedPainter(color: Colors.black.withOpacity(0.1)),
        ),
      );
    } else if (texture == 'dots') {
      textureOverlay = ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          size: Size.infinite,
          painter: _DotPainter(color: Colors.white.withOpacity(0.1)),
        ),
      );
    }

    // 데이터
    final name = data['name'] ?? "Guest";
    final photoUrl = data['photoUrl'];
    final subtitle = data['role'] ?? data['bio'] ?? ""; 
    final detail = data['company'] ?? data['location'] ?? "";
    final contact = data['phone'] ?? data['email'] ?? data['instagram'] ?? "";
    final String? mbti = data['mbti'];
    final String? birthday = data['birthday'];

    return Stack(
      children: [
        Container(
          width: double.infinity,
          decoration: baseDecoration,
          child: const SizedBox(height: 200),
        ),
        if (textureOverlay != null) Positioned.fill(child: textureOverlay),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 상단 프로필 ---
              Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      image: photoUrl != null ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                      color: Colors.black26,
                    ),
                    child: photoUrl == null ? const Icon(Icons.person, color: Colors.white70, size: 30) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        // MBTI 뱃지 (Social 모드일 때만 표시)
                        if (modeIndex == 1 && mbti != null && mbti.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(mbti, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          )
                        else
                          Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(modeLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.2), height: 1),
              const SizedBox(height: 20),

              // --- Social Mode Layout (Bio, Tag, Song 제거됨) ---
              if (modeIndex == 1) ...[
                // 남은 요소: 생일 & SNS 링크만 깔끔하게 한 줄(또는 두 줄)로 배치
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 정렬
                  children: [
                    // 생일
                    if (birthday != null && birthday.isNotEmpty)
                      _buildIconText(Icons.cake, birthday),

                    // SNS 링크 (우측 배치)
                    if (contact.isNotEmpty)
                      GestureDetector(
                        onTap: () => _launchSmartLink(context, contact, type: 'sns'),
                        child: _buildIconText(Icons.link, contact, isLink: true),
                      ),
                  ],
                )

              ] else ...[
                // Business & Private Mode (기존 유지)
                if (detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildIconText(Icons.business, detail),
                  ),
                if (contact.isNotEmpty)
                  GestureDetector(
                    onTap: () => _launchSmartLink(context, contact, type: 'contact'),
                    child: _buildIconText(contact.contains('@') ? Icons.email : Icons.phone, contact, isLink: true),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconText(IconData icon, String text, {bool isLink = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isLink ? Colors.white : Colors.white70),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text, 
            style: TextStyle(
              fontSize: 14, 
              color: isLink ? Colors.white : Colors.white.withOpacity(0.9),
              decoration: isLink ? TextDecoration.underline : TextDecoration.none,
              fontWeight: isLink ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StripedPainter extends CustomPainter {
  final Color color;
  _StripedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    for (double i = -size.height; i < size.width; i += 10) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotPainter extends CustomPainter {
  final Color color;
  _DotPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const double step = 20;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if ((x / step).floor() % 2 == (y / step).floor() % 2) {
           canvas.drawCircle(Offset(x + 10, y + 10), 2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}