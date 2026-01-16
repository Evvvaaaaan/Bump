import 'package:bump/core/services/database_service.dart';
import 'package:bump/features/card/card_detail_screen.dart'; // [필수] 상세 화면 파일 import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    // 로그인이 안 된 경우 처리
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.white))),
      );
    }

    final dbService = ref.watch(databaseServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("내 명함첩", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      // [핵심 1] DatabaseService에서 contacts 컬렉션을 가져오는 함수 연결
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: dbService.getConnectionsStream(uid), 
        builder: (context, snapshot) {
          // 에러 처리
          if (snapshot.hasError) {
            return Center(child: Text("오류가 발생했습니다: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }
          // 로딩 처리
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final contacts = snapshot.data ?? [];

          // 데이터가 없을 때
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.folder_off_outlined, size: 60, color: Colors.white24),
                  SizedBox(height: 20),
                  Text("저장된 명함이 없습니다.", style: TextStyle(color: Colors.white54)),
                ],
              ),
            );
          }

          // 리스트 출력
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: contacts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final contact = contacts[index];

              // [핵심 2] 데이터 필드 추출 (contacts 구조는 snapshot 껍데기 없이 바로 데이터가 있음)
              final name = contact['name'] ?? '이름 없음';
              final role = contact['role'] ?? contact['bio'] ?? '';
              final detail = contact['company'] ?? contact['location'] ?? '';
              final photoUrl = contact['photoUrl'];

              // [핵심 3] 클릭 이벤트 추가 (GestureDetector)
              return GestureDetector(
                onTap: () {
                  // 상세 화면으로 이동하며 데이터 전달
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardDetailScreen(cardData: contact),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      // 프로필 이미지
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      // 텍스트 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (role.isNotEmpty || detail.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                "$role ${detail.isNotEmpty ? '· $detail' : ''}",
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
                        ),
                      ),
                      // 화살표 아이콘
                      const Icon(Icons.chevron_right, color: Colors.white24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}