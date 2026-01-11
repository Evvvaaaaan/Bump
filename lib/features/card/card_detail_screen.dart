import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/features/home/widgets/bump_card.dart'; // [필수] 홈 화면의 카드 위젯 재사용
import 'package:flutter/material.dart';

class CardDetailScreen extends StatelessWidget {
  final Map<String, dynamic> cardData;

  const CardDetailScreen({
    super.key, 
    this.cardData = const {},
  });

  @override
  Widget build(BuildContext context) {
    // 1. 모드 파악 로직
    // 데이터에 'mode' 정보가 없으면, 필드를 보고 추측하거나 기본값(Business)을 사용합니다.
    int modeIndex = 0; // 기본값: Business
    
    if (cardData['mode'] == 'social' || cardData.containsKey('mbti')) {
      modeIndex = 1; // Social
    } else if (cardData['mode'] == 'private') {
      modeIndex = 2; // Private
    }

    // 2. 모드에 따른 테마 색상 설정
    Color primaryColor = AppColors.businessPrimary;
    if (modeIndex == 1) primaryColor = AppColors.socialPrimary;
    else if (modeIndex == 2) primaryColor = AppColors.privatePrimary;

    return Scaffold(
      // 홈 화면과 비슷한 분위기를 위해 어두운 배경 적용
      backgroundColor: const Color(0xFF121212), 
      appBar: AppBar(
        title: const Text("명함 상세"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          // 3. 홈 화면과 똑같은 BumpCard 위젯 사용
          child: BumpCard(
            modeIndex: modeIndex,
            primaryColor: primaryColor,
            data: cardData,
          ),
        ),
      ),
    );
  }
}