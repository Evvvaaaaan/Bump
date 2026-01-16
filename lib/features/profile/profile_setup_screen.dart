import 'dart:io';
import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/core/services/auth_service.dart'; // [필수] 로그아웃 위해 추가
import 'package:bump/features/design/card_design_screen.dart';
import 'package:bump/features/home/widgets/bump_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // 이동 처리를 위해 추가
import 'package:image_picker/image_picker.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 텍스트 컨트롤러들
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _roleCtrl = TextEditingController(); // Business, Private에서만 사용
  final TextEditingController _detailCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  
  // Social 모드 전용 컨트롤러 (취미, 노래 삭제됨)
  final TextEditingController _mbtiCtrl = TextEditingController();
  final TextEditingController _birthCtrl = TextEditingController();
  // final TextEditingController _musicCtrl = TextEditingController(); // [삭제]
  // final TextEditingController _hobbyCtrl = TextEditingController(); // [삭제]
  
  File? _pickedImage;
  String? _currentPhotoUrl;
  Map<String, dynamic> _currentStyle = {}; 
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
    _nameCtrl.dispose(); _roleCtrl.dispose(); _detailCtrl.dispose(); _contactCtrl.dispose();
    _mbtiCtrl.dispose(); _birthCtrl.dispose(); 
    // _musicCtrl.dispose(); _hobbyCtrl.dispose(); // [삭제]
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadDataForMode(_tabController.index);
    }
  }

  // [추가] 로그아웃 핸들러
  Future<void> _handleLogout() async {
    try {
      await AuthService().signOut(); // AuthService의 signOut 호출
      if (mounted) context.go('/login'); // 로그인 화면으로 이동
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("로그아웃 실패: $e")));
    }
  }

  Future<void> _loadDataForMode(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 초기화
    _nameCtrl.clear(); _roleCtrl.clear(); _detailCtrl.clear(); _contactCtrl.clear();
    _mbtiCtrl.clear(); _birthCtrl.clear(); 
    // _musicCtrl.clear(); _hobbyCtrl.clear(); // [삭제]

    setState(() {
      _pickedImage = null;
      _currentPhotoUrl = null;
      _currentStyle = {};
    });

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
            _currentStyle = profile['style'] ?? {};

            if (index == 1) { // Social
              // [수정] Social에서 상태메시지, 취미, 노래 로드 부분 삭제
              _detailCtrl.text = profile['location'] ?? "";
              _contactCtrl.text = profile['instagram'] ?? "";
              _mbtiCtrl.text = profile['mbti'] ?? "";
              _birthCtrl.text = profile['birthday'] ?? "";
            } else { // Business & Private
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
        'style': _currentStyle,
      };

      if (modeIdx == 1) { // Social
        // [수정] 상태메시지(bio), 취미, 노래 저장 로직 삭제
        data['location'] = _detailCtrl.text;
        data['instagram'] = _contactCtrl.text;
        data['mbti'] = _mbtiCtrl.text;
        data['birthday'] = _birthCtrl.text;
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

    // 미리보기 데이터
    final previewData = {
      'name': _nameCtrl.text.isEmpty ? '이름' : _nameCtrl.text,
      'photoUrl': _pickedImage != null ? null : _currentPhotoUrl,
      'style': _currentStyle,
      if (isSocial) ...{
        // [수정] Social 미리보기 데이터에서 삭제된 필드 제거
        'mbti': _mbtiCtrl.text,
        'birthday': _birthCtrl.text,
        'instagram': _contactCtrl.text,
        'location': _detailCtrl.text,
      } else ...{
        'role': _roleCtrl.text,
        'company': _detailCtrl.text,
        'phone': _contactCtrl.text,
        'location': _detailCtrl.text,
        'email': _contactCtrl.text,
      }
    };

    ImageProvider? profileImageProvider;
    if (_pickedImage != null) {
      profileImageProvider = FileImage(_pickedImage!);
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      profileImageProvider = NetworkImage(_currentPhotoUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("프로필 편집", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        // [추가] 로그아웃 버튼
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _handleLogout,
            tooltip: "로그아웃",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: "Business"), Tab(text: "Social"), Tab(text: "Private")],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            BumpCard(
              modeIndex: _tabController.index,
              primaryColor: primaryColor,
              data: previewData,
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: profileImageProvider,
                    child: profileImageProvider == null
                        ? const Icon(Icons.camera_alt, size: 24, color: Colors.white70)
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDesignScreen(modeIndex: _tabController.index),
                      ),
                    ).then((_) => _loadDataForMode(_tabController.index));
                  },
                  icon: Icon(Icons.palette, color: primaryColor),
                  label: Text("명함 꾸미기", style: TextStyle(color: primaryColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            _buildTextField("이름 (Name)", _nameCtrl),
            
            if (isSocial) ...[
              // [수정] 상태 메시지, 취미, 노래 필드 삭제됨
              Row(
                children: [
                  Expanded(child: _buildTextField("MBTI", _mbtiCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField("생일 (MM.DD)", _birthCtrl)),
                ],
              ),
              _buildTextField("지역 (Location)", _detailCtrl),
              _buildTextField("인스타그램 / SNS", _contactCtrl),
            ] else ...[
              _buildTextField(_tabController.index == 0 ? "직함 (Role)" : "상태 메시지", _roleCtrl),
              _buildTextField(_tabController.index == 0 ? "회사 (Company)" : "지역 (Location)", _detailCtrl),
              _buildTextField(_tabController.index == 0 ? "전화번호" : "이메일/연락처", _contactCtrl),
            ],

            const SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("저장하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 50),
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
          filled: true, fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
        ),
      ),
    );
  }
}