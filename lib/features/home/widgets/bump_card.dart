
import 'package:flutter/material.dart';

class BumpCard extends StatelessWidget {
  final Map<String, dynamic> data; // 명함 데이터 (name, role, etc.)
  final int modeIndex; // 0: Business, 1: Social, 2: Private
  final Color primaryColor;

  const BumpCard({
    super.key,
    required this.data,
    required this.modeIndex,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    // 모드별 라벨
    final modeLabel = ['Business', 'Social', 'Private'][modeIndex];

    // 데이터 안전하게 가져오기 (null 처리 포함)
    final name = data['name'] ?? "Guest";
    final subtitle = data['role'] ?? data['bio'] ?? "No description";
    final detail = data['company'] ?? data['location'] ?? "No details";
    final contact = data['phone'] ?? data['email'] ?? "";
    final photoUrl = data['photoUrl'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // 유리 효과 느낌의 반투명 배경
        color: Colors.white.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 상단: 아바타 + 이름 + 모드 배지 ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 아바타
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
              
              // 이름 및 직함 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: -0.5
                        ),
                        overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                        overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // 모드 배지 (우측 상단)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.5)),
                ),
                child: Text(modeLabel,
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w600, 
                      color: primaryColor.withOpacity(0.9) // 텍스트 가독성을 위해 밝기 조정 필요 시 수정
                    )
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 24),

          // --- 하단: 상세 정보 ---
          // 회사/위치 정보
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(detail, 
                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9))
                ),
              ),
            ],
          ),
          
          // 연락처 정보 (있을 때만 표시)
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.link, size: 16, color: Colors.white.withOpacity(0.6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(contact, 
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))
                  ),
                ),
              ],
            )
          ]
        ],
      ),
    );
  }
}