import 'dart:io';
import 'package:bump/features/home/home_screen.dart';
import 'package:bump/core/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; 

class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key});

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // 공통
  final _nameController = TextEditingController();
  
  // Business
  final _roleController = TextEditingController();
  final _companyController = TextEditingController();
  final _logoController = TextEditingController(); 
  final _bizPhoneController = TextEditingController();
  final _bizEmailController = TextEditingController();
  final _websiteController = TextEditingController();

  // Social
  final _mbtiController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _instagramController = TextEditingController();
  final _kakaoController = TextEditingController();

  // Private
  final _privatePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _privateEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  int get _currentModeIndex => ref.read(modeProvider);
  String get _currentModeKey => ['business', 'social', 'private'][_currentModeIndex];

  Future<void> _loadCurrentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dbService = ref.read(databaseServiceProvider);
    final userData = await dbService.getUserData(user.uid);
    
    if (userData != null && userData['profiles'] != null) {
      final profile = userData['profiles'][_currentModeKey] ?? {};
      
      setState(() {
        _nameController.text = profile['name'] ?? '';

        if (_currentModeIndex == 0) { // Business
          _roleController.text = profile['role'] ?? '';
          _companyController.text = profile['company'] ?? '';
          _logoController.text = profile['logoUrl'] ?? ''; 
          _bizPhoneController.text = profile['phone'] ?? '';
          _bizEmailController.text = profile['email'] ?? '';
          _websiteController.text = profile['website'] ?? '';
        } 
        else if (_currentModeIndex == 1) { // Social
          _mbtiController.text = profile['mbti'] ?? '';
          _birthdateController.text = profile['birthdate'] ?? '';
          _instagramController.text = profile['instagram'] ?? '';
          _kakaoController.text = profile['kakaoId'] ?? '';
        } 
        else if (_currentModeIndex == 2) { // Private
          _privatePhoneController.text = profile['phone'] ?? '';
          _addressController.text = profile['address'] ?? '';
          _privateEmailController.text = profile['email'] ?? '';
        }
      });
    }
  }

  // 로고 업로드
  Future<void> _pickAndUploadLogo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploading = true);

      final storageRef = FirebaseStorage.instance.ref().child('users/${user.uid}/logo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(File(image.path));
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        _logoController.text = downloadUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("로고가 업로드되었습니다.")));
      }
    } catch (e) {
      print(e);
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미지 업로드 실패")));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dbService = ref.read(databaseServiceProvider);
    
    // 기존 테마 정보 유지
    final userData = await dbService.getUserData(user.uid);
    Map<String, dynamic> existingTheme = {};
    if (userData != null && userData['profiles'] != null) {
       existingTheme = userData['profiles'][_currentModeKey]?['theme'] ?? {};
    }

    Map<String, dynamic> profileData = {
      'name': _nameController.text,
      'theme': existingTheme, // 테마 유지
    };

    if (_currentModeIndex == 0) { // Business
      profileData.addAll({
        'role': _roleController.text,
        'company': _companyController.text,
        'logoUrl': _logoController.text, 
        'phone': _bizPhoneController.text,
        'email': _bizEmailController.text,
        'website': _websiteController.text,
      });
    } else if (_currentModeIndex == 1) { // Social
      profileData.addAll({
        'mbti': _mbtiController.text,
        'birthdate': _birthdateController.text,
        'instagram': _instagramController.text,
        'kakaoId': _kakaoController.text,
      });
    } else if (_currentModeIndex == 2) { // Private
      profileData.addAll({
        'phone': _privatePhoneController.text,
        'address': _addressController.text,
        'email': _privateEmailController.text,
      });
    }

    await dbService.updateProfile(
      uid: user.uid,
      mode: _currentModeKey,
      data: profileData,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

                // 2. 예쁜 플로팅 스낵바 띄우기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        // 성공 아이콘 (파란색)
                        const Icon(Icons.check_circle, color: Color(0xFF4B6EFF), size: 20),
                        const SizedBox(width: 12),
                        // 텍스트
                        Text(
                          "정보 수정 완료!",
                          style: GoogleFonts.notoSans(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF333333), // 진한 회색 배경
                    behavior: SnackBarBehavior.floating,      // [핵심] 화면 위에 둥둥 뜨게 만듦
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 40), // [핵심] 하단에서 40px 띄움
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // 모서리 둥글게
                    ),
                    duration: const Duration(seconds: 2), // 2초 뒤 사라짐
                    elevation: 4, // 그림자 효과
                  ),
                );

                // 3. 화면 닫기
                Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          _currentModeIndex == 0 ? "Business 정보 수정" 
          : _currentModeIndex == 1 ? "Social 정보 수정" 
          : "Private 정보 수정",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text("저장", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("기본 정보", style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 10),
              _buildTextField("이름 (실명 또는 닉네임)", _nameController),
              const SizedBox(height: 24),
              
              // ==========================================
              // [Business 입력 폼]
              // ==========================================
              if (_currentModeIndex == 0) ...[
                const Text("비즈니스 정보", style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 10),
                _buildTextField("직함 / 역할 (예: 개발자, 학생)", _roleController),
                const SizedBox(height: 16),
                _buildTextField("회사 / 학교명", _companyController),
                const SizedBox(height: 16),
                
                // 로고 업로더
                const Text("회사 로고", style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadLogo,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            image: _logoController.text.isNotEmpty
                                ? DecorationImage(image: NetworkImage(_logoController.text), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _isUploading 
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : (_logoController.text.isEmpty 
                                  ? const Icon(Icons.add_a_photo, color: Colors.grey) 
                                  : null),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _logoController.text.isEmpty ? "로고 이미지 업로드" : "로고 변경하기",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "탭하여 갤러리에서 선택하세요",
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text("연락처 & 링크", style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 10),
                _buildTextField("업무용 전화번호", _bizPhoneController, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField("업무용 이메일", _bizEmailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField("웹사이트 URL", _websiteController, keyboardType: TextInputType.url),
              ],

              // ==========================================
              // [Social 입력 폼]
              // ==========================================
              if (_currentModeIndex == 1) ...[
                const Text("소셜 정보", style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 10),
                _buildTextField("MBTI / 소개", _mbtiController),
                const SizedBox(height: 16),
                _buildTextField("생일 (YYYY-MM-DD)", _birthdateController),
                const SizedBox(height: 24),
                const Text("SNS & 메신저", style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 10),
                _buildTextField("Instagram ID", _instagramController),
                const SizedBox(height: 16),
                _buildTextField("KakaoTalk ID / 링크", _kakaoController),
              ],

              // ==========================================
              // [Private 입력 폼]
              // ==========================================
              if (_currentModeIndex == 2) ...[
                const Text("개인 연락처", style: TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 10),
                _buildTextField("개인 전화번호", _privatePhoneController, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField("집 주소", _addressController),
                const SizedBox(height: 16),
                _buildTextField("개인 이메일", _privateEmailController, keyboardType: TextInputType.emailAddress),
              ],

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}