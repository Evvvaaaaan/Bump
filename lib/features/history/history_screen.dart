import 'package:bump/core/services/database_service.dart';
import 'package:bump/features/card/card_detail_screen.dart'; // 상세 화면 경로 확인 필요
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bump/features/common/skeleton_loader.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final dbService = ref.watch(databaseServiceProvider);

    // 로그인 체크
    if (uid == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("CONTACTS", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(), // 홈으로 복귀
        ),
        centerTitle: false,
      ),
      
      body: Column(
        children: [
          // 1. 검색창 추가
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.blueAccent,
                decoration: const InputDecoration(
                  hintText: "이름 검색...",
                  hintStyle: TextStyle(color: Colors.grey),
                  icon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // 2. 명함 리스트 (기존 dbService 로직 유지)
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: dbService.getConnectionsStream(uid), 
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("오류: ${snapshot.error}", style: const TextStyle(color: Colors.white54)));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonContactList(); 
                }

                final allContacts = snapshot.data ?? [];

                // [검색 필터링 로직]
                final contacts = allContacts.where((contact) {
                  // 기존 코드의 데이터 구조 반영
                  final data = contact['profile'] ?? contact;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return _searchText.isEmpty || name.contains(_searchText);
                }).toList();

                if (contacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.style_outlined, size: 60, color: Colors.grey[800]),
                        const SizedBox(height: 20),
                        Text(
                          _searchText.isEmpty ? "저장된 명함이 없습니다." : "검색 결과가 없습니다.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];

                    // 기존 코드의 UI 및 데이터 추출 로직 유지
                    final data = contact['profile'] ?? contact; 
                    final name = data['name'] ?? '이름 없음';
                    final role = data['role'] ?? data['mbti'] ?? '';
                    final company = data['company'] ?? '';
                    final photoUrl = data['logoUrl'] ?? data['photoUrl'];

                    return GestureDetector(
                      onTap: () {
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
          ),
        ],
      ),

      // 3. 홈 화면과 동일한 Bottom Navigation Bar 추가
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: 1, // Contacts 탭 활성화
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 0) {
            context.pop(); // Home으로 이동
          } else if (index == 2) {
            context.push('/bump'); // Bump 화면 이동
          } else if (index == 3) {
            context.push('/settings');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_outlined, size: 28), label: 'Contacts'),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF4B6EFF),
              child: Icon(Icons.sensors, color: Colors.white, size: 28),
            ), 
            label: 'Bump'
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 28), label: 'Settings'),
        ],
      ),
    );
  }
}