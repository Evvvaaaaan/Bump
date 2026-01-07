import 'package:bump/core/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // 입력 컨트롤러
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true; // 로딩 상태 시작

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // [핵심] 화면 진입 시 기존 정보 불러오기
  }

  // 기존 프로필 데이터 로드 함수
  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // DB에서 내 정보 가져오기
      final userData = await ref.read(databaseServiceProvider).getUserData(user.uid);
      
      if (userData != null && userData['profiles'] != null) {
        // 비즈니스 프로필 데이터 추출
        final businessProfile = userData['profiles']['business'] as Map<String, dynamic>?;
        
        if (businessProfile != null) {
          // [핵심] 컨트롤러에 기존 값 채워넣기
          setState(() {
            _nameController.text = businessProfile['name'] ?? '';
            _companyController.text = businessProfile['company'] ?? '';
            _roleController.text = businessProfile['role'] ?? '';
            _phoneController.text = businessProfile['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      print("프로필 로드 오류: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("로그인이 필요합니다.");

      final businessCardData = {
        'name': _nameController.text,
        'company': _companyController.text,
        'role': _roleController.text,
        'phone': _phoneController.text,
        'isActive': true,
        'theme': 'classic_navy',
      };

      await ref.read(databaseServiceProvider).updateProfile(
        uid: user.uid,
        mode: 'business',
        data: businessCardData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("명함이 저장되었습니다!")),
        );
        context.pop(); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이면 스피너 표시
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("비즈니스 명함 편집", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.person, color: Colors.white54, size: 50),
                ),
              ),
              const SizedBox(height: 40),
              
              _buildTextField("이름", _nameController, "이름을 입력하세요"),
              const SizedBox(height: 16),
              _buildTextField("회사 / 소속", _companyController, "소속을 입력하세요"),
              const SizedBox(height: 16),
              _buildTextField("직책 / 역할", _roleController, "직책을 입력하세요"),
              const SizedBox(height: 16),
              _buildTextField("연락처", _phoneController, "010-0000-0000", isNumber: true),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B6EFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("저장하기", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          validator: (value) => value == null || value.isEmpty ? "$label을(를) 입력해주세요" : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}