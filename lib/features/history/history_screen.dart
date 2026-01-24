import 'package:bump/core/services/database_service.dart';
import 'package:bump/features/card/card_detail_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
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
        title: Text("내 명함첩", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: dbService.getConnectionsStream(uid), 
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("오류: ${snapshot.error}", style: const TextStyle(color: Colors.white54)));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined, size: 60, color: Colors.grey[800]),
                  const SizedBox(height: 20),
                  Text("저장된 명함이 없습니다.", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: contacts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final contact = contacts[index];

              // 리스트에 보여줄 간략 정보 추출
              final data = contact['profile'] ?? contact; 
              final name = data['name'] ?? '이름 없음';
              final role = data['role'] ?? data['mbti'] ?? '';
              final company = data['company'] ?? '';
              final photoUrl = data['logoUrl'] ?? data['photoUrl'];

              return GestureDetector(
                onTap: () {
                  // [중요] contact 데이터 전체를 상세 화면으로 전달
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardDetailScreen(cardData: contact),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                          image: (photoUrl != null && photoUrl.toString().isNotEmpty)
                              ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: (photoUrl == null || photoUrl.toString().isEmpty)
                            ? const Icon(Icons.person, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.notoSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            if (role.isNotEmpty || company.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                "$role ${company.isNotEmpty ? '| $company' : ''}",
                                style: GoogleFonts.notoSans(color: Colors.white54, fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
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