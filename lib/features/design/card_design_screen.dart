import 'package:bump/core/services/database_service.dart';
// [기존 디자인]
import 'package:bump/features/editor/widgets/minimal_template_card.dart';
import 'package:bump/features/editor/widgets/dark_geometric_card.dart';
import 'package:bump/features/editor/widgets/paper_texture_card.dart';
// [신규 디자인 임포트 추가]
import 'package:bump/features/editor/widgets/glassmorphism_card.dart';
import 'package:bump/features/editor/widgets/aurora_gradient_card.dart';
import 'package:bump/features/editor/widgets/neo_brutalism_card.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardDesignScreen extends ConsumerStatefulWidget {
  final int modeIndex;
  const CardDesignScreen({super.key, required this.modeIndex});
  @override
  ConsumerState<CardDesignScreen> createState() => _CardDesignScreenState();
}

class _CardDesignScreenState extends ConsumerState<CardDesignScreen> {
  String _selectedTemplateId = 'minimal_beige';
  bool _isLoading = false;
  Map<String, dynamic> _previewData = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentDesign();
  }

  String get _currentModeKey => ['business', 'social', 'private'][widget.modeIndex];

  Future<void> _loadCurrentDesign() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final profile = data['profiles']?[_currentModeKey] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _previewData = profile ?? {};
          if (profile != null && profile.containsKey('theme')) {
             final theme = profile['theme'];
             _selectedTemplateId = theme['templateId'] ?? 'minimal_beige';
          }
        });
      }
    }
  }

  Future<void> _saveDesign() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profiles': {
          _currentModeKey: {
            'theme': { 'type': 'template', 'templateId': _selectedTemplateId }
          }
        }
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("디자인 저장 완료!")));
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> livePreviewData = Map.from(_previewData);
    livePreviewData['theme'] = { 'type': 'template', 'templateId': _selectedTemplateId };

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("명함 디자인"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDesign,
            child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("완료", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. 상단 미리보기
          Expanded(
            flex: 6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildPreviewCard(livePreviewData),
              ),
            ),
          ),
          
          // 2. 하단 디자인 선택
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("템플릿 선택", style: TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 20), // 간격 조정
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // --- [NEW] 새로운 디자인 ---
                        _buildDesignOption("Glass", Icons.blur_on, "glass_morphism"),
                        const SizedBox(width: 12),
                        _buildDesignOption("Aurora", Icons.palette, "aurora_gradient"),
                        const SizedBox(width: 12),
                        _buildDesignOption("Neo Brutal", Icons.tag, "neo_brutalism"),
                        const SizedBox(width: 12),
                        
                        // --- [기존 디자인] ---
                        _buildDesignOption("Dark Geo", Icons.hexagon, "dark_geometric"),
                        const SizedBox(width: 12),
                        _buildDesignOption("Minimal", Icons.light_mode, "minimal_beige"),
                        const SizedBox(width: 12),
                        _buildDesignOption("Paper W", Icons.description, "paper_white"),
                        const SizedBox(width: 12),
                        _buildDesignOption("Paper K", Icons.recycling, "paper_kraft"),
                        const SizedBox(width: 12),
                        _buildDesignOption("Paper L", Icons.grid_on, "paper_linen"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> data) {
    // [수정] 모든 템플릿 케이스 연결
    switch (_selectedTemplateId) {
      // --- 신규 ---
      case 'glass_morphism':
        return GlassmorphismCard(data: data, modeIndex: widget.modeIndex);
      case 'aurora_gradient':
        return AuroraGradientCard(data: data, modeIndex: widget.modeIndex);
      case 'neo_brutalism':
        return NeoBrutalismCard(data: data, modeIndex: widget.modeIndex);
      
      // --- 기존 ---
      case 'dark_geometric':
        return DarkGeometricCard(data: data, modeIndex: widget.modeIndex);
      case 'paper_white':
        return PaperTextureCard(data: data, modeIndex: widget.modeIndex, type: PaperType.white);
      case 'paper_kraft':
        return PaperTextureCard(data: data, modeIndex: widget.modeIndex, type: PaperType.kraft);
      case 'paper_linen':
        return PaperTextureCard(data: data, modeIndex: widget.modeIndex, type: PaperType.linen);
      case 'minimal_beige':
      default:
        return MinimalTemplateCard(data: data, modeIndex: widget.modeIndex);
    }
  }

  Widget _buildDesignOption(String label, IconData icon, String id) {
    bool isSelected = _selectedTemplateId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTemplateId = id),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isSelected ? Colors.black : Colors.white54),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}