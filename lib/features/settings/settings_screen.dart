
// 파일 경로: lib/features/settings/settings_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isNotiEnabled = true;
  bool _isHapticEnabled = true;
  String _appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if(mounted) setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(), // 뒤로가기
        ),
        title: Text("SETTINGS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("GENERAL"),
            _buildSwitchTile(
              icon: Icons.notifications_none, title: "푸시 알림", value: _isNotiEnabled,
              onChanged: (v) => setState(() => _isNotiEnabled = v),
            ),
            _buildSwitchTile(
              icon: Icons.vibration, title: "햅틱 반응", subtitle: "Bump 시 진동", value: _isHapticEnabled,
              onChanged: (v) => setState(() => _isHapticEnabled = v),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader("SUPPORT"),
            _buildActionTile(icon: Icons.mail_outline, title: "문의하기 / 버그 신고", onTap: _sendEmail),
            
            const SizedBox(height: 24),

            _buildSectionHeader("INFORMATION"),
            // [중요] 실제 출시 전 아래 URL을 본인의 노션 페이지나 웹사이트 주소로 변경해야 합니다.
            _buildActionTile(icon: Icons.description_outlined, title: "이용약관", onTap: () => _launchUrl("https://example.com/terms")),
            _buildActionTile(icon: Icons.privacy_tip_outlined, title: "개인정보 처리방침", onTap: () => _launchUrl("https://example.com/privacy")),
            _buildActionTile(icon: Icons.code, title: "오픈소스 라이선스", onTap: () => showLicensePage(context: context, applicationName: "BUMP", applicationIcon: const Icon(Icons.sensors, size: 48))),
            _buildInfoTile("앱 버전", _appVersion),

            const SizedBox(height: 24),

            _buildSectionHeader("ACCOUNT"),
            _buildActionTile(icon: Icons.logout, title: "로그아웃", onTap: _showLogoutDialog),
            _buildActionTile(icon: Icons.person_remove_outlined, title: "회원 탈퇴", textColor: Colors.redAccent, onTap: _showDeleteAccountDialog),
            
            const SizedBox(height: 40),
            Center(child: Text("© 2026 BUMP Team. All rights reserved.", style: GoogleFonts.notoSans(color: Colors.white24, fontSize: 12))),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- 위젯 빌더 및 함수들 (동일) ---
  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 12), child: Text(title, style: GoogleFonts.outfit(color: const Color(0xFF4B6EFF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)));
  }
  Widget _buildSwitchTile({required IconData icon, required String title, String? subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)), child: SwitchListTile(value: value, onChanged: onChanged, activeColor: const Color(0xFF4B6EFF), secondary: Icon(icon, color: Colors.white70), title: Text(title, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)), subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.notoSans(color: Colors.white38, fontSize: 12)) : null));
  }
  Widget _buildActionTile({required IconData icon, required String title, Color textColor = Colors.white, required VoidCallback onTap}) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)), child: ListTile(onTap: onTap, leading: Icon(icon, color: textColor.withOpacity(0.7)), title: Text(title, style: GoogleFonts.notoSans(color: textColor, fontSize: 15, fontWeight: FontWeight.w500)), trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14)));
  }
  Widget _buildInfoTile(String title, String value) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: GoogleFonts.notoSans(color: Colors.white70, fontSize: 15)), Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))]));
  }
  void _launchUrl(String url) async { final uri = Uri.parse(url); if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication); }
  void _sendEmail() async { final Uri emailLaunchUri = Uri(scheme: 'mailto', path: 'support@bumpapp.com', query: 'subject=[BUMP] 문의사항&body=내용을 입력해주세요.'); if (await canLaunchUrl(emailLaunchUri)) await launchUrl(emailLaunchUri); }
  void _showLogoutDialog() { showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF222222), title: const Text("로그아웃", style: TextStyle(color: Colors.white)), content: const Text("정말 로그아웃 하시겠습니까?", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.white54))), TextButton(onPressed: () async { Navigator.pop(context); await FirebaseAuth.instance.signOut(); if (mounted) context.go('/login'); }, child: const Text("로그아웃", style: TextStyle(color: Colors.redAccent)))])); }
  void _showDeleteAccountDialog() { showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF222222), title: const Text("회원 탈퇴", style: TextStyle(color: Colors.redAccent)), content: const Text("계정을 삭제하면 모든 정보가 영구 삭제됩니다.\n정말 탈퇴하시겠습니까?", style: TextStyle(color: Colors.white70)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소", style: TextStyle(color: Colors.white54))), TextButton(onPressed: () async { Navigator.pop(context); try { await FirebaseAuth.instance.currentUser?.delete(); if (mounted) context.go('/login'); } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("재로그인 후 시도해주세요."))); } }, child: const Text("탈퇴하기", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))])); }
}