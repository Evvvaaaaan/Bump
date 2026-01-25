import 'package:bump/features/common/scale_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class UnifiedPermissionScreen extends StatefulWidget {
  const UnifiedPermissionScreen({super.key});

  @override
  State<UnifiedPermissionScreen> createState() => _UnifiedPermissionScreenState();
}

// [수정 1] 앱의 상태(백그라운드/포그라운드)를 감지하기 위해 Observer 추가
class _UnifiedPermissionScreenState extends State<UnifiedPermissionScreen> with WidgetsBindingObserver {
  PermissionStatus _locationStatus = PermissionStatus.denied;
  PermissionStatus _notificationStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    // [수정 2] 앱 상태 감지기 등록
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    // [수정 3] 감지기 해제 (메모리 누수 방지)
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // [수정 4] 앱이 다시 활성화될 때(설정창이나 팝업에서 돌아왔을 때) 권한 재확인
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final loc = await Permission.location.status;
    final noti = await Permission.notification.status;
    
    if (mounted) {
      setState(() {
        _locationStatus = loc;
        _notificationStatus = noti;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    // 권한 요청
    final status = await permission.request();
    
    // [중요] 요청 직후 상태 업데이트
    if (mounted) {
      setState(() {
        if (permission == Permission.location) _locationStatus = status;
        if (permission == Permission.notification) _notificationStatus = status;
      });
    }

    // 만약 '영구 거절(permanentlyDenied)' 상태라면 설정창으로 유도
    // (사용자가 '다시 묻지 않음'을 체크했거나, iOS에서 거절한 경우)
    if (status.isPermanentlyDenied) {
      if (mounted) _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("권한 설정 필요", style: TextStyle(color: Colors.white)),
        content: const Text("설정에서 권한을 직접 '허용'으로 변경해주세요.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // 설정창 열기
            }, 
            child: const Text("설정으로 이동", style: TextStyle(color: Colors.blueAccent))
          ),
        ],
      ),
    );
  }

  void _onStartApp() {
    // 위치 권한이 허용되었는지 확인
    if (_locationStatus.isGranted || _locationStatus.isLimited) { // iOS의 경우 limited도 허용으로 간주
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("BUMP를 사용하려면 위치 권한이 꼭 필요해요!")),
      );
      _requestPermission(Permission.location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text("편리한 사용을 위해\n권한을 허용해주세요", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
              const SizedBox(height: 10),
              Text("권한을 허용하지 않아도 앱을 사용할 수 있지만,\n일부 기능이 제한될 수 있습니다.", style: GoogleFonts.notoSans(fontSize: 14, color: Colors.white54, height: 1.5)),
              
              const SizedBox(height: 50),

              _buildPermissionItem(
                icon: Icons.place,
                title: "위치 정보 (필수)",
                description: "주변에 있는 사용자를 찾아 명함을 교환합니다.",
                status: _locationStatus,
                onTap: () => _requestPermission(Permission.location),
              ),
              
              const SizedBox(height: 24),

              _buildPermissionItem(
                icon: Icons.notifications_active,
                title: "알림 (선택)",
                description: "매칭 성공 및 명함 교환 알림을 받습니다.",
                status: _notificationStatus,
                onTap: () => _requestPermission(Permission.notification),
              ),

              const Spacer(),

              ScaleButton(
                onTap: _onStartApp,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (_locationStatus.isGranted || _locationStatus.isLimited) 
                        ? const Color(0xFF4B6EFF) 
                        : const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      (_locationStatus.isGranted || _locationStatus.isLimited) ? "BUMP 시작하기" : "위치 권한을 허용해주세요",
                      style: GoogleFonts.notoSans(
                        color: (_locationStatus.isGranted || _locationStatus.isLimited) ? Colors.white : Colors.white38,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
    required VoidCallback onTap,
  }) {
    // iOS의 'Limited(대략적인 위치)' 권한도 허용으로 간주
    final isGranted = status.isGranted || status.isLimited;

    return ScaleButton(
      onTap: isGranted ? () {} : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: isGranted ? Border.all(color: const Color(0xFF4B6EFF), width: 1.5) : Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGranted ? const Color(0xFF4B6EFF).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isGranted ? const Color(0xFF4B6EFF) : Colors.white54, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description, style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isGranted)
              const Icon(Icons.check_circle, color: Color(0xFF4B6EFF), size: 28)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                child: const Text("허용", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}