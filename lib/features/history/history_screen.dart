import 'package:bump/core/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("로그인 필요")));

    return Scaffold(
      appBar: AppBar(
        title: Text("명함첩", style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(databaseServiceProvider).getConnectionsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("오류: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final list = snapshot.data!;

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style_outlined, size: 60, color: Colors.white24),
                  const SizedBox(height: 20),
                  const Text("아직 교환한 명함이 없습니다.", style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = list[index];
              // DB에 저장된 snapshot 데이터 가져오기
              final data = item['snapshot'] as Map<String, dynamic>? ?? {};
              
              return Card(
                color: Colors.white10,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  onTap: () {
                    // [핵심] 상세 화면으로 데이터 전달하며 이동
                    context.push('/card_detail', extra: data);
                  },
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF4B6EFF),
                    child: Text(
                      (data['name'] as String?)?.substring(0, 1) ?? "?",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    data['name'] ?? "이름 없음", 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                  subtitle: Text(
                    "${data['company'] ?? ''} · ${data['role'] ?? ''}",
                    style: const TextStyle(color: Colors.white60)
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
                ),
              );
            },
          );
        },
      ),
    );
  }
}