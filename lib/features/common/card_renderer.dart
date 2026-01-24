import 'package:flutter/material.dart';

// [필수] 모든 디자인 위젯 임포트
import 'package:bump/features/editor/widgets/minimal_template_card.dart';
import 'package:bump/features/editor/widgets/dark_geometric_card.dart';
import 'package:bump/features/editor/widgets/paper_texture_card.dart';
import 'package:bump/features/editor/widgets/glassmorphism_card.dart';
import 'package:bump/features/editor/widgets/aurora_gradient_card.dart';
import 'package:bump/features/editor/widgets/neo_brutalism_card.dart';
// import 'package:bump/features/editor/widgets/dark_modern_card.dart'; // 필요시 주석 해제

class CardRenderer extends StatelessWidget {
  final Map<String, dynamic> data;
  final int modeIndex;

  const CardRenderer({
    super.key,
    required this.data,
    required this.modeIndex,
  });

  @override
  Widget build(BuildContext context) {
    // [핵심 해결책] 데이터 평탄화 (Flattening)
    // profile 안에 숨어있는 정보들을 끄집어내어 최상위로 만듭니다.
    final Map<String, dynamic> safeData = _flattenData(data);

    // 테마 정보 안전하게 추출
    final theme = safeData['theme'] as Map<String, dynamic>? ?? {};
    final templateId = theme['templateId'] ?? 'minimal_beige';

    // 모드 인덱스 재확인 (데이터 안에 포함된 경우 우선 적용)
    final int safeModeIndex = safeData['modeIndex'] is int 
        ? safeData['modeIndex'] 
        : modeIndex;

    switch (templateId) {
      case 'glass_morphism':
        return GlassmorphismCard(data: safeData, modeIndex: safeModeIndex);
        
      case 'neo_brutalism':
        return NeoBrutalismCard(data: safeData, modeIndex: safeModeIndex);
      
      case 'aurora_gradient':
        return AuroraGradientCard(data: safeData, modeIndex: safeModeIndex);

      case 'dark_geometric':
        return DarkGeometricCard(data: safeData, modeIndex: safeModeIndex);
      
      case 'paper_white':
        return PaperTextureCard(data: safeData, modeIndex: safeModeIndex, type: PaperType.white);
      
      case 'paper_kraft':
        return PaperTextureCard(data: safeData, modeIndex: safeModeIndex, type: PaperType.kraft);
      
      case 'paper_linen':
        return PaperTextureCard(data: safeData, modeIndex: safeModeIndex, type: PaperType.linen);
      
      // case 'dark_modern':
      //   return DarkModernCard(data: safeData, modeIndex: safeModeIndex);
      
      case 'minimal_beige':
      default:
        return MinimalTemplateCard(data: safeData, modeIndex: safeModeIndex);
    }
  }

  // [데이터 구조 정리 함수]
  Map<String, dynamic> _flattenData(Map<String, dynamic> source) {
    // 1. 원본 복사
    Map<String, dynamic> result = Map.from(source);

    // 2. 'profile' 키가 있다면 그 안의 내용을 밖으로 꺼냄
    if (source['profile'] != null && source['profile'] is Map) {
      final profileMap = Map<String, dynamic>.from(source['profile']);
      result.addAll(profileMap);
      
      // theme가 profile 안에 있으면 밖으로 꺼냄
      if (profileMap['theme'] != null) {
        result['theme'] = profileMap['theme'];
      }
    }
    
    // 3. 'theme'가 없다면 원본의 theme 확인
    if (result['theme'] == null && source['theme'] != null) {
      result['theme'] = source['theme'];
    }

    return result;
  }
}