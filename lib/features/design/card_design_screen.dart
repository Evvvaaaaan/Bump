import 'package:bump/features/home/widgets/bump_card.dart';
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

class _CardDesignScreenState extends ConsumerState<CardDesignScreen> with SingleTickerProviderStateMixin {
  late TabController _colorTabController;
  String _selectedColorType = 'gradient'; // 'solid' or 'gradient'
  int _selectedColorId = 0;
  String _selectedTexture = 'glass'; // 'glass' or 'metal'
  bool _isLoading = false;
  Map<String, dynamic> _previewData = {};

  // 색상 프리셋 (BumpCard와 동일하게 맞춰야 함)
  final List<Color> _solidColors = [
    Colors.grey.shade800, const Color(0xFF1A237E), const Color(0xFF004D40),
    const Color(0xFFB71C1C), const Color(0xFF4A148C), Colors.black,
  ];
  final List<List<Color>> _gradientColors = [
    [const Color(0xFF434343), const Color(0xFF000000)],
    [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
    [const Color(0xFF614385), const Color(0xFF516395)],
    [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
    [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
  ];
  // 질감 옵션
  final List<Map<String, dynamic>> _textureOptions = [
    {'id': 'glass', 'label': '유리', 'icon': Icons.blur_on},
    {'id': 'metal', 'label': '메탈', 'icon': Icons.horizontal_rule},
  ];

  @override
  void initState() {
    super.initState();
    _colorTabController = TabController(length: 2, vsync: this);
    _colorTabController.addListener(() {
      if (_colorTabController.indexIsChanging) {
        setState(() {
          _selectedColorType = _colorTabController.index == 0 ? 'solid' : 'gradient';
          _selectedColorId = 0; // 탭 변경 시 선택 초기화
        });
      }
    });
    _loadCurrentDesign();
  }

  @override
  void dispose() {
    _colorTabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentDesign() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final modeKey = ['business', 'social', 'private'][widget.modeIndex];
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final profile = data['profiles']?[modeKey] as Map<String, dynamic>?;
      setState(() {
        _previewData = profile ?? {};
        if (profile != null && profile.containsKey('style')) {
          _selectedColorType = profile['style']['colorType'] ?? 'gradient';
          _selectedColorId = profile['style']['colorId'] ?? 0;
          _selectedTexture = profile['style']['texture'] ?? 'glass';
          _colorTabController.index = _selectedColorType == 'solid' ? 0 : 1;
        }
      });
    }
  }

  Future<void> _saveDesign() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    final modeKey = ['business', 'social', 'private'][widget.modeIndex];
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'profiles': {
          modeKey: {
            'style': {
              'colorType': _selectedColorType,
              'colorId': _selectedColorId,
              'texture': _selectedTexture,
            }
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
    livePreviewData['style'] = {
      'colorType': _selectedColorType,
      'colorId': _selectedColorId,
      'texture': _selectedTexture,
    };

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("명함 디자인"),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveDesign,
            child: const Text("완료", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. 미리보기 영역
          Expanded(
            flex: 5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: BumpCard(
                  data: livePreviewData,
                  modeIndex: widget.modeIndex,
                  primaryColor: Colors.white,
                ),
              ),
            ),
          ),
          // 2. 컨트롤 패널
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 색상 선택 탭
                  TabBar(
                    controller: _colorTabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    tabs: const [Tab(text: "단색 (Solid)"), Tab(text: "그라데이션")],
                  ),
                  const SizedBox(height: 20),
                  // 색상 팔레트
                  SizedBox(
                    height: 60,
                    child: TabBarView(
                      controller: _colorTabController,
                      physics: const NeverScrollableScrollPhysics(), // 스와이프 방지
                      children: [
                        // 단색 팔레트
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _solidColors.length,
                          itemBuilder: (context, index) => _buildColorItem(index, color: _solidColors[index]),
                        ),
                        // 그라데이션 팔레트
                        ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _gradientColors.length,
                          itemBuilder: (context, index) => _buildColorItem(index, gradient: _gradientColors[index]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 질감 선택
                  const Text("Texture (질감)", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    children: _textureOptions.map((option) {
                      return _buildTextureOption(option['id'], option['label'], option['icon']);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 색상 아이템 위젯
  Widget _buildColorItem(int index, {Color? color, List<Color>? gradient}) {
    bool isSelected = _selectedColorId == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedColorId = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 16),
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          gradient: gradient != null ? LinearGradient(colors: gradient) : null,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : Border.all(color: Colors.white24, width: 1),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 10)] : [],
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }

  // 질감 선택 버튼 위젯
  Widget _buildTextureOption(String value, String label, IconData icon) {
    bool isSelected = _selectedTexture == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTexture = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: isSelected ? Colors.black : Colors.white54),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}