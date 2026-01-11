import 'dart:io';
import 'package:bump/core/constants/app_colors.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:bump/features/home/widgets/bump_card.dart'; // 명함 미리보기용
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
  
  // 입력 컨트롤러 (현재 탭의 내용)
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _roleCtrl = TextEditingController(); // 직함 or Bio
  final TextEditingController _detailCtrl = TextEditingController(); // 회사 or 위치
  final TextEditingController _contactCtrl = TextEditingController(); // 전화 or 이메일
  
  File? _pickedImage;
  String? _currentPhotoUrl; // 기존 이미지 URL
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 3개 탭 (Business, Social, Private)
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // 첫 화면 데이터 로드
    _loadDataForMode(0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _detailCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  // 탭이 바뀔 때마다 실행
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadDataForMode(_tabController.index);
    }
  }

  // DB에서 해당 모드의 데이터 가져오기
  Future<void> _loadDataForMode(int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 입력창 초기화
    _nameCtrl.text = "";
    _roleCtrl.text = "";
    _detailCtrl.text = "";
    _contactCtrl.text = "";
    setState(() {
      _pickedImage = null;
      _currentPhotoUrl = null;
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
            // 모드별 필드 매핑
            if (index == 0) { // Business
              _roleCtrl.text = profile['role'] ?? "";
              _detailCtrl.text = profile['company'] ?? "";
              _contactCtrl.text = profile['phone'] ?? "";
            } else { // Social & Private
              _roleCtrl.text = profile['bio'] ?? "";
              _detailCtrl.text = profile['location'] ?? "";
              _contactCtrl.text = profile['email'] ?? "";
            }
            _currentPhotoUrl = profile['photoUrl'];
          });
        }
      }
    } catch (e) {
      print("데이터 로드 오류: $e");
    }
  }

  // 갤러리에서 이미지 선택
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }

  // 저장 버튼 클릭 시
  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      final modeIdx = _tabController.index;
      final modeKey = ['business', 'social', 'private'][modeIdx];
      
      String? photoUrl = _currentPhotoUrl;

      // 1. 새 이미지가 있다면 업로드
      if (_pickedImage != null) {
        photoUrl = await ref.read(databaseServiceProvider)
            .uploadProfileImage(uid, modeKey, _pickedImage!);
      }

      // 2. 저장할 데이터 구성
      final Map<String, dynamic> data = {
        'name': _nameCtrl.text,
        'photoUrl': photoUrl,
      };

      if (modeIdx == 0) { // Business
        data['role'] = _roleCtrl.text;
        data['company'] = _detailCtrl.text;
        data['phone'] = _contactCtrl.text;
      } else { // Social & Private
        data['bio'] = _roleCtrl.text;
        data['location'] = _detailCtrl.text;
        data['email'] = _contactCtrl.text;
      }

      // 3. DB 업데이트
      await ref.read(databaseServiceProvider).updateProfile(
        uid: uid,
        mode: modeKey,
        data: data,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${['Business', 'Social', 'Private'][modeIdx]} 프로필 저장 완료!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("저장 실패: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 탭에 따른 테마 색상
    Color primaryColor;
    if (_tabController.index == 0) primaryColor = AppColors.businessPrimary;
    else if (_tabController.index == 1) primaryColor = AppColors.socialPrimary;
    else primaryColor = AppColors.privatePrimary;

    // 텍스트 필드 라벨 (모드별 다르게 표시)
    String roleLabel = _tabController.index == 0 ? "직함 (Role)" : "상태 메시지 (Bio)";
    String detailLabel = _tabController.index == 0 ? "회사 (Company)" : "지역 (Location)";
    String contactLabel = _tabController.index == 0 ? "전화번호 (Phone)" : "이메일/SNS";

    return Scaffold(
      appBar: AppBar(
        title: const Text("프로필 편집"),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Business"),
            Tab(text: "Social"),
            Tab(text: "Private"),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 명함 미리보기 (실시간 반영)
            BumpCard(
              modeIndex: _tabController.index,
              primaryColor: primaryColor,
              data: {
                'name': _nameCtrl.text.isEmpty ? '이름 입력' : _nameCtrl.text,
                'role': _roleCtrl.text,
                'bio': _roleCtrl.text,
                'company': _detailCtrl.text,
                'location': _detailCtrl.text,
                'phone': _contactCtrl.text,
                'email': _contactCtrl.text,
                'photoUrl': _pickedImage != null ? null : _currentPhotoUrl, // 로컬 이미지는 아래 아바타에서 확인
              },
            ),
            const SizedBox(height: 20),

            // 2. 사진 변경 버튼
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _pickedImage != null 
                        ? FileImage(_pickedImage!) 
                        : (_currentPhotoUrl != null ? NetworkImage(_currentPhotoUrl!) : null) as ImageProvider?,
                    child: (_pickedImage == null && _currentPhotoUrl == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.white54)
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. 입력 필드
            _buildTextField("이름 (Name)", _nameCtrl),
            _buildTextField(roleLabel, _roleCtrl),
            _buildTextField(detailLabel, _detailCtrl),
            _buildTextField(contactLabel, _contactCtrl),
            
            const SizedBox(height: 40),

            // 4. 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("저장하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
        // 입력할 때마다 화면 갱신 (미리보기 반영)
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1)),
        ),
      ),
    );
  }
}