import 'package:bump/features/settings/settings_provider.dart'; // [필수] 설정 상태 관리자 Provider
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 클립보드 기능
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart'; 

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

// [핵심] WidgetsBindingObserver: 앱의 생명주기(Foreground/Background)를 감지하기 위해 추가
class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool _isDeleting = false; // 회원 탈퇴 로딩 상태
  String _appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    // 1. 앱 상태 감지기 등록
    WidgetsBinding.instance.addObserver(this);
    
    // 2. 앱 버전 로드
    _loadAppVersion();
    
    // 3. 화면에 들어오자마자 최신 알림 권한 상태 확인 (싱크 맞추기)
    Future.microtask(() => 
      ref.read(settingsProvider.notifier).refreshNotificationStatus()
    );
  }

  @override
  void dispose() {
    // 4. 감지기 해제 (메모리 누수 방지)
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // [핵심 기능] 앱이 백그라운드(설정창)에서 다시 돌아왔을 때 실행됨
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("🔄 앱 복귀 감지: 알림 권한 상태를 재확인합니다.");
      ref.read(settingsProvider.notifier).refreshNotificationStatus();
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  // --- [다이얼로그 및 기능 함수들] ---

  // 1. 문의하기 다이얼로그 (이메일 복사 기능)
  void _showContactDialog() {
    const contactEmail = "vmfhrmfoald36@gmail.com";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("문의하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "버그 신고나 문의사항은\n아래 이메일로 보내주세요.",
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline, color: Colors.white54, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      contactEmail,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: contactEmail));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("이메일 주소가 복사되었습니다!")),
              );
            },
            icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
            label: const Text("주소 복사", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인", style: TextStyle(color: Color(0xFF4B6EFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2. 로그아웃 다이얼로그
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("로그아웃", style: TextStyle(color: Colors.white)),
        content: const Text("정말 로그아웃 하시겠습니까?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) context.go('/login');
            },
            child: const Text("로그아웃", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // 3. 회원 탈퇴 로직
  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("회원 탈퇴", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "계정을 삭제하면 모든 정보가 영구 삭제됩니다.\n정말 탈퇴하시겠습니까?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("탈퇴하기", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true); // 로딩 시작

    try {
      await FirebaseAuth.instance.currentUser?.delete();
      if (mounted) {
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("회원 탈퇴가 완료되었습니다.")));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false); // 로딩 해제
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다. 재로그인 후 다시 시도해주세요.")));
      }
    }
  }

  // --- [UI 빌드] ---

  @override
  Widget build(BuildContext context) {
    // [중요] Provider 상태 구독 (settings_provider.dart에서 정의됨)
    final settingsState = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text("SETTINGS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("GENERAL"),
            
            // [푸시 알림] 시스템 설정과 동기화됨
            _buildSwitchTile(
              icon: Icons.notifications_none,
              title: "푸시 알림",
              value: settingsState.isNotiEnabled, // 실제 시스템 권한 상태
              onChanged: (v) => settingsNotifier.toggleNotification(v), // 클릭 시 권한 요청 or 설정창 이동
            ),
            
            // [햅틱 반응] 내부 설정
            _buildSwitchTile(
              icon: Icons.vibration,
              title: "햅틱 반응",
              subtitle: "Bump 시 진동",
              value: settingsState.isHapticEnabled,
              onChanged: (v) => settingsNotifier.toggleHaptic(v),
            ),
            
            const SizedBox(height: 24),

            _buildSectionHeader("SUPPORT"),
            _buildActionTile(icon: Icons.mail_outline, title: "문의하기 / 버그 신고", onTap: _showContactDialog),
            
            const SizedBox(height: 24),

            _buildSectionHeader("INFORMATION"),
            _buildActionTile(icon: Icons.description_outlined, title: "이용약관", onTap: () => context.push('/terms')),
            _buildActionTile(icon: Icons.privacy_tip_outlined, title: "개인정보 처리방침", onTap: () => context.push('/privacy')),
            _buildActionTile(
              icon: Icons.code, 
              title: "오픈소스 라이선스", 
              onTap: () => showLicensePage(context: context, applicationName: "BUMP", applicationIcon: const Icon(Icons.sensors, size: 48))
            ),
            _buildInfoTile("앱 버전", _appVersion),

            const SizedBox(height: 24),

            _buildSectionHeader("ACCOUNT"),
            _buildActionTile(icon: Icons.logout, title: "로그아웃", onTap: _showLogoutDialog),
            
            _buildActionTile(
              icon: Icons.person_remove_outlined, 
              title: "회원 탈퇴", 
              textColor: Colors.redAccent, 
              onTap: _isDeleting ? () {} : _handleDeleteAccount, 
              isLoading: _isDeleting 
            ),
            
            const SizedBox(height: 40),
            Center(child: Text("© 2026 BUMP Team. All rights reserved.", style: GoogleFonts.notoSans(color: Colors.white24, fontSize: 12))),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- [공용 위젯 빌더] ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(title, style: GoogleFonts.outfit(color: const Color(0xFF4B6EFF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4B6EFF),
        secondary: Icon(icon, color: Colors.white70),
        title: Text(title, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 12)) : null,
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String title, Color textColor = Colors.white, required VoidCallback onTap, bool isLoading = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: isLoading ? null : onTap,
        leading: Icon(icon, color: textColor.withOpacity(0.7)),
        title: Text(title, style: GoogleFonts.notoSans(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent)) 
            : const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 15)),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}