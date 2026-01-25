import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonContactList extends StatelessWidget {
  const SkeletonContactList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 6, // 화면을 꽉 채울 정도의 가짜 개수
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const _SkeletonTile(),
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    // BUMP 앱의 다크 테마에 맞춘 색상
    const baseColor = Color(0xFF1E1E1E); // 카드 배경색과 비슷하게
    const highlightColor = Color(0xFF2C2C2C); // 빛나는 색상

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02), // 아주 희미한 배경
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          children: [
            // 1. 프로필 이미지 스켈레톤
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            
            // 2. 텍스트 라인 스켈레톤
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 자리
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 직함/회사 자리
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // 3. 화살표 자리
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}