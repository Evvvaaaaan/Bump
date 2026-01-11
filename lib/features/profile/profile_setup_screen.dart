import 'dart:io';
import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/features/home/widgets/bump_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 공통 입력
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _roleCtrl = TextEditingController();   // Role / Bio
  final TextEditingController _detailCtrl = TextEditingController(); // Company / Location
  final TextEditingController _contactCtrl = TextEditingController(); // Phone / SNS
  
  // [New] Social 전용 입력
  final TextEditingController _mbtiCtrl = TextEditingController();
  final TextEditingController _musicCtrl = TextEditingController();
  final TextEditingController _birthCtrl = TextEditingController();
  final TextEditingController _hobbyCtrl = TextEditingController(); // 쉼표로 구분
  
  File? _pickedImage;
  String? _currentPhotoUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadDataForMode(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _detailCtrl.dispose();
    _contactCtrl.dispose();
    _mbtiCtrl.dispose();
    _musicCtrl.dispose();
    _birthCtrl.dispose();
    _hobbyCtrl.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadDataForMode(_tabController.index);
    }
  }

  Future<void> _loadDataForMode(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 초기화
    _nameCtrl.text = ""; _roleCtrl.text = ""; _detailCtrl.text = ""; _contactCtrl.text = "";
    _mbtiCtrl.text = ""; _musicCtrl.text = ""; _birthCtrl.text = ""; _hobbyCtrl.text = "";
    setState(() { _pickedImage = null; _currentPhotoUrl = null; });

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final profiles = data['profiles'] as Map<String, dynamic>?;
        final modeKey = ['business', 'social', 'private'][index];
        final profile = profiles?[modeKey];

        if (profile != null) {
          setState(() {
            _nameCtrl.text = profile['name'] ?? "";
            _currentPhotoUrl = profile['photoUrl'];

            if (index == 1) { // Social
              _roleCtrl.text = profile['bio'] ?? "";
              _detailCtrl.text = profile['location'] ?? ""; // Social에선 잘 안쓰지만 유지
              _contactCtrl.text = profile['instagram'] ?? ""; // SNS 링크로 사용
              // Social 추가 필드
              _mbtiCtrl.text = profile['mbti'] ?? "";
              _musicCtrl.text = profile['music'] ?? "";
              _birthCtrl.text = profile['birthday'] ?? "";
              // 리스트를 문자열로 변환 (UI 표시용)
              final List hobbies = profile['hobbies'] ?? [];
              _hobbyCtrl.text = hobbies.join(', ');
            } else { 
              // Business & Private
              _roleCtrl.text = profile['role'] ?? profile['bio'] ?? "";
              _detailCtrl.text = profile['company'] ?? profile['location'] ?? "";
              _contactCtrl.text = profile['phone'] ?? profile['email'] ?? "";
            }
          });
        }
      }
    } catch (e) {
      print("데이터 로드 오류: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      final modeIdx = _tabController.index;
      final modeKey = ['business', 'social', 'private'][modeIdx];
      
      String? photoUrl = _currentPhotoUrl;
      if (_pickedImage != null) {
        photoUrl = await ref.read(databaseServiceProvider)
            .uploadProfileImage(uid, modeKey, _pickedImage!);
      }

      final Map<String, dynamic> data = {
        'name': _nameCtrl.text,
        'photoUrl': photoUrl,
      };

      if (modeIdx == 1) { // Social
        data['bio'] = _roleCtrl.text;
        data['location'] = _detailCtrl.text;
        data['instagram'] = _contactCtrl.text; // SNS 필드로 활용
        // 추가 정보 저장
        data['mbti'] = _mbtiCtrl.text;
        data['music'] = _musicCtrl.text;
        data['birthday'] = _birthCtrl.text;
        // 쉼표로 구분된 취미를 리스트로 변환
        data['hobbies'] = _hobbyCtrl.text.split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (modeIdx == 0) { // Business
        data['role'] = _roleCtrl.text;
        data['company'] = _detailCtrl.text;
        data['phone'] = _contactCtrl.text;
      } else { // Private
        data['bio'] = _roleCtrl.text;
        data['location'] = _detailCtrl.text;
        data['email'] = _contactCtrl.text;
      }

      await ref.read(databaseServiceProvider).updateProfile(
        uid: uid,
        mode: modeKey,
        data: data,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장 완료!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = [AppColors.businessPrimary, AppColors.socialPrimary, AppColors.privatePrimary][_tabController.index];
    final isSocial = _tabController.index == 1;

    // 미리보기용 데이터 생성
    final previewData = {
      'name': _nameCtrl.text.isEmpty ? '이름' : _nameCtrl.text,
      'photoUrl': _pickedImage != null ? null : _currentPhotoUrl,
      if (isSocial) ...{
        'bio': _roleCtrl.text,
        'mbti': _mbtiCtrl.text,
        'music': _musicCtrl.text,
        'birthday': _birthCtrl.text,
        'hobbies': _hobbyCtrl.text.split(',').map((e) => e.trim()).toList(),
        'instagram': _contactCtrl.text,
      } else ...{
        'role': _roleCtrl.text,
        'bio': _roleCtrl.text,
        'company': _detailCtrl.text,
        'location': _detailCtrl.text,
        'phone': _contactCtrl.text,
        'email': _contactCtrl.text,
      }
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("프로필 편집"),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          tabs: const [Tab(text: "Business"), Tab(text: "Social"), Tab(text: "Private")],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 미리보기 카드
            BumpCard(
              modeIndex: _tabController.index,
              primaryColor: primaryColor,
              data: previewData,
            ),
            const SizedBox(height: 20),
            
            // 2. 사진 변경
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[800],
                backgroundImage: _pickedImage != null ? FileImage(_pickedImage!) : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) : null) as ImageProvider?,
                child: (_pickedImage == null && _currentPhotoUrl == null) ? const Icon(Icons.camera_alt) : null,
              ),
            ),
            const SizedBox(height: 30),

            // 3. 입력 필드
            _buildTextField("이름 (Name)", _nameCtrl),
            
            if (isSocial) ...[
              // Social Mode Inputs
              _buildTextField("상태 메시지 (Bio)", _roleCtrl),
              Row(
                children: [
                  Expanded(child: _buildTextField("MBTI", _mbtiCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField("생일 (MM.DD)", _birthCtrl)),
                ],
              ),
              _buildTextField("취미 (쉼표로 구분, 예: 독서, 서핑)", _hobbyCtrl),
              _buildTextField("좋아하는 노래 (Music)", _musicCtrl),
              _buildTextField("인스타그램 / SNS", _contactCtrl),
            ] else ...[
              // Business & Private Inputs
              _buildTextField(_tabController.index == 0 ? "직함 (Role)" : "상태 메시지", _roleCtrl),
              _buildTextField(_tabController.index == 0 ? "회사 (Company)" : "지역 (Location)", _detailCtrl),
              _buildTextField(_tabController.index == 0 ? "전화번호" : "이메일/연락처", _contactCtrl),
            ],

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("저장하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          filled: true, fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}