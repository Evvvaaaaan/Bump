import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 상태 클래스
class SettingsState {
  final bool isNotiEnabled; // 시스템 알림 권한 상태
  final bool isHapticEnabled; // 앱 내 햅틱 설정 상태

  SettingsState({this.isNotiEnabled = false, this.isHapticEnabled = true});

  SettingsState copyWith({bool? isNotiEnabled, bool? isHapticEnabled}) {
    return SettingsState(
      isNotiEnabled: isNotiEnabled ?? this.isNotiEnabled,
      isHapticEnabled: isHapticEnabled ?? this.isHapticEnabled,
    );
  }
}

// 상태 관리자 (Notifier)
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  // 초기 실행 시 시스템 상태 확인
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isHaptic = prefs.getBool('isHapticEnabled') ?? true;
    
    // [핵심] 앱 켤 때 실제 알림 권한 확인
    final notiStatus = await Permission.notification.status;
    
    state = state.copyWith(
      isHapticEnabled: isHaptic,
      isNotiEnabled: notiStatus.isGranted, // 실제 허용 여부 대입
    );
  }

  // [기능 추가] 시스템 권한 상태를 강제로 다시 확인 (새로고침)
  Future<void> refreshNotificationStatus() async {
    final status = await Permission.notification.status;
    // 실제 상태와 내 앱의 상태가 다르면 업데이트
    if (state.isNotiEnabled != status.isGranted) {
      state = state.copyWith(isNotiEnabled: status.isGranted);
    }
  }

  // 햅틱 토글
  Future<void> toggleHaptic(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHapticEnabled', value);
    state = state.copyWith(isHapticEnabled: value);
  }

  // 알림 토글 (스위치 눌렀을 때)
  Future<void> toggleNotification(bool value) async {
    if (value) {
      // OFF -> ON 시도: 권한 요청
      final status = await Permission.notification.request();
      
      if (status.isPermanentlyDenied || status.isDenied) {
        // 영구 거절된 경우 설정창으로 유도
        await openAppSettings();
      }
      // 요청 결과 반영
      final newStatus = await Permission.notification.status;
      state = state.copyWith(isNotiEnabled: newStatus.isGranted);
      
    } else {
      // ON -> OFF 시도: 앱에서 끌 수 없음 -> 설정창으로 이동
      await openAppSettings();
      // (사용자가 설정창에서 끄고 돌아오면 Lifecycle에서 감지하여 업데이트됨)
    }
  }
}

// Provider 선언
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});