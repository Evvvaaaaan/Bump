import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================================================================
  // 1. 프로필 관리 (Profile)
  // ==================================================================

  // 내 프로필 저장/업데이트
  Future<void> updateProfile({
    required String uid,
    required String mode,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'profiles': {
          mode: data, // 예: business: { name: '홍길동', ... }
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ 프로필($mode) 저장 완료");
    } catch (e) {
      print("❌ 프로필 저장 실패: $e");
      throw e;
    }
  }

  // 내 정보 가져오기 (1회성)
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print("❌ 데이터 불러오기 실패: $e");
      return null;
    }
  }

  // 내 정보 실시간 감시 (Stream) - 홈 화면용
  Stream<DocumentSnapshot> getProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // ==================================================================
  // 2. 명함 교환 및 히스토리 (Connections)
  // ==================================================================

  // 상대방 명함 저장 (매칭 성공 시)
  Future<void> saveConnection({
    required String myUid,
    required String partnerUid,
    required Map<String, dynamic> partnerData,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(myUid)
          .collection('connections')
          .doc(partnerUid)
          .set({
        'partnerUid': partnerUid,
        'metAt': FieldValue.serverTimestamp(),
        'snapshot': partnerData, // 만난 시점의 데이터 박제
      });
      print("✅ 명함 교환 저장 완료 (${partnerData['name']})");
    } catch (e) {
      print("❌ 명함 저장 실패: $e");
    }
  }

  // 내 명함첩 목록 가져오기 (Stream) - 히스토리 화면용
  Stream<List<Map<String, dynamic>>> getConnectionsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('connections')
        .orderBy('metAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ==================================================================
  // 3. 범프 매칭 시스템 (Bump Matching)
  // ==================================================================

  // 매칭 요청 등록 (슬라이드 시)
  Future<String> createBumpRequest(String uid, Map<String, dynamic> myCardData) async {
    print("🚀 [DEBUG] createBumpRequest 호출됨! UID: $uid");
    try {
      DocumentReference ref = await _db.collection('bump_requests').add({
        'requesterUid': uid,
        'cardData': myCardData,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'searching',
        'matchedWith': null,
      });
      print("✅ [DEBUG] 매칭 요청 생성됨 ID: ${ref.id}");
      return ref.id;
    } catch (e) {
      print("❌ [DEBUG] 매칭 요청 생성 실패: $e");
      rethrow;
    }
  }

  // 매칭 요청 취소 (화면 나갈 때)
  Future<void> cancelBumpRequest(String requestId) async {
    try {
      await _db.collection('bump_requests').doc(requestId).delete();
      print("🧹 매칭 요청 삭제 완료 ($requestId)");
    } catch (e) {
      print("❌ 삭제 실패: $e");
    }
  }

  // 내 요청 상태 감시 (매칭 성사 여부 확인용)
  Stream<DocumentSnapshot> getBumpRequestStream(String requestId) {
    return _db.collection('bump_requests').doc(requestId).snapshots();
  }

  // 매칭 시도 로직 (상대방 찾기)
  Future<void> findAndMatch(String myRequestId, String myUid) async {
    // 5초 이내의 유효한 요청만 검색 (유령 데이터 방지)
    final now = DateTime.now();
    final validTime = now.subtract(const Duration(seconds: 5));

    try {
      QuerySnapshot query = await _db
          .collection('bump_requests')
          .where('status', isEqualTo: 'searching')
          .where('timestamp', isGreaterThan: validTime)
          .limit(5)
          .get();

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // 내 요청이거나 이미 나인 경우 패스
        if (doc.id == myRequestId) continue;
        if (data['requesterUid'] == myUid) continue;

        String partnerRequestId = doc.id;

        // 트랜잭션으로 안전하게 매칭 성사
        await _db.runTransaction((transaction) async {
          DocumentSnapshot partnerDoc = await transaction.get(doc.reference);
          if (!partnerDoc.exists) return; // 이미 삭제된 요청이면 패스

          // 1. 상대방 문서 업데이트 (너는 나랑 매칭됐어)
          transaction.update(doc.reference, {
            'status': 'matched',
            'matchedWith': myUid,
            'matchedRequestId': myRequestId,
          });

          // 2. 내 문서 업데이트 (나는 너랑 매칭됐어)
          transaction.update(_db.collection('bump_requests').doc(myRequestId), {
            'status': 'matched',
            'matchedWith': data['requesterUid'],
            'partnerCardData': data['cardData'],
          });
        });

        print("🎉 매칭 성공! 상대방: ${data['requesterUid']}");
        return; // 매칭 성공 시 종료
      }
    } catch (e) {
      print("⚠️ 매칭 시도 중 오류(또는 경합): $e");
    }
  }
}