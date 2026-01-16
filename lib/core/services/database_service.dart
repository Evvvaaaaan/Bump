import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

class DatabaseService {
  // [변수 선언]
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // 호환성을 위한 getter
  FirebaseFirestore get _firestore => _db; 

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
          mode: data,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ 프로필($mode) 저장 완료");
    } catch (e) {
      print("❌ 프로필 저장 실패: $e");
      throw e;
    }
  }

  // 프로필 이미지 업로드
  Future<String> uploadProfileImage(String uid, String mode, File imageFile) async {
    try {
      final ref = _storage.ref().child('users/$uid/${mode}_profile.jpg');
      TaskSnapshot snapshot = await ref.putFile(imageFile);
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (e) {
      print("❌ 이미지 업로드 실패: $e");
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

  // 내 정보 실시간 감시 (Stream)
  Stream<DocumentSnapshot> getProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // ==================================================================
  // 2. 명함 교환 및 히스토리 (Contacts로 통합됨)
  // ==================================================================

  // [범프 매칭용] 상대방 명함 저장
  // ==================================================================
  // 2. 명함 교환 및 히스토리 (완벽 통일 버전)
  // ==================================================================

  // [저장 1] 범프 매칭 시 저장
  Future<void> saveConnection({
    required String myUid,
    required String partnerUid,
    required Map<String, dynamic> partnerData,
  }) async {
    if (partnerUid.isEmpty) return;

    try {
      await _db
          .collection('users')
          .doc(myUid)
          .collection('contacts')
          .doc(partnerUid) // [중요] 문서 ID는 무조건 상대방 UID
          .set({
            ...partnerData, // [중요] 데이터를 쫙 펼쳐서 저장 (Flat)
            'uid': partnerUid,
            'savedAt': FieldValue.serverTimestamp(),
            'isBumped': true,
          }); // [중요] 덮어쓰기 방지
      print("✅ 범프 저장 완료");
    } catch (e) {
      print("❌ 범프 저장 실패: $e");
    }
  }
  
  // [저장 2] 리스트에서 수동 저장
  Future<void> saveContact({
    required String myUid, 
    required String targetUid, 
    required Map<String, dynamic> targetProfileData
  }) async {
    if (targetUid.isEmpty) throw Exception("UID 없음");

    try {
      await _db
          .collection('users')
          .doc(myUid)
          .collection('contacts')
          .doc(targetUid) // [중요] 문서 ID는 무조건 상대방 UID
          .set({
            ...targetProfileData, // [중요] 데이터를 쫙 펼쳐서 저장
            'uid': targetUid,
            'savedAt': FieldValue.serverTimestamp(),
            'isBumped': false,
          }); // [중요] 덮어쓰기 방지
      print("✅ 수동 저장 완료");
    } catch (e) {
      print("❌ 수동 저장 실패: $e");
      throw Exception("저장 실패");
    }
  }

  // [불러오기] 명함첩 목록 (contacts 컬렉션)
  Stream<List<Map<String, dynamic>>> getConnectionsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('contacts') // 경로 확인
        .orderBy('savedAt', descending: true) // 정렬 확인
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  // ==================================================================
  // 3. 범프 매칭 시스템 (Bump Matching)
  // ==================================================================

  // 매칭 요청 생성
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
      return ref.id;
    } catch (e) {
      print("❌ [DEBUG] 매칭 요청 생성 실패: $e");
      rethrow;
    }
  }

  // 매칭 요청 취소
  Future<void> cancelBumpRequest(String requestId) async {
    try {
      await _db.collection('bump_requests').doc(requestId).delete();
      print("🧹 매칭 요청 삭제 완료 ($requestId)");
    } catch (e) {
      print("❌ 삭제 실패: $e");
    }
  }

  // 요청 상태 감시
  Stream<DocumentSnapshot> getBumpRequestStream(String requestId) {
    return _db.collection('bump_requests').doc(requestId).snapshots();
  }

  // 매칭 시도 로직
  Future<void> findAndMatch(String myRequestId, String myUid) async {
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

        if (doc.id == myRequestId) continue;
        if (data['requesterUid'] == myUid) continue;

        await _db.runTransaction((transaction) async {
          DocumentSnapshot partnerDoc = await transaction.get(doc.reference);
          if (!partnerDoc.exists) return; 

          transaction.update(doc.reference, {
            'status': 'matched',
            'matchedWith': myUid,
            'matchedRequestId': myRequestId,
          });

          transaction.update(_db.collection('bump_requests').doc(myRequestId), {
            'status': 'matched',
            'matchedWith': data['requesterUid'],
            'partnerCardData': data['cardData'],
          });
        });

        print("🎉 매칭 성공! 상대방: ${data['requesterUid']}");
        return; 
      }
    } catch (e) {
      print("⚠️ 매칭 시도 중 오류: $e");
    }
  }
}