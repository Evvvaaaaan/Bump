import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart'; // [필수] 위치 정보 패키지
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
  // 2. 명함 교환 및 히스토리 (Contacts)
  // ==================================================================

  // [저장 1] 범프 매칭 시 저장 (교체 모드)
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
          .doc(partnerUid) // 상대방 UID를 키로 사용
          .set({
            ...partnerData,
            'uid': partnerUid,
            'savedAt': FieldValue.serverTimestamp(),
            'isBumped': true,
          }); // merge 옵션 제거 (새 정보로 교체)
          
      print("✅ 범프 명함 교체 완료");
    } catch (e) {
      print("❌ 저장 실패: $e");
    }
  }
  
  // [저장 2] 리스트에서 수동 저장 (교체 모드)
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
          .doc(targetUid) // 상대방 UID를 키로 사용
          .set({
            ...targetProfileData,
            'uid': targetUid,
            'savedAt': FieldValue.serverTimestamp(),
            'isBumped': false,
          }); // merge 옵션 제거 (새 정보로 교체)
          
      print("✅ 수동 명함 교체 완료");
    } catch (e) {
      print("❌ 저장 실패: $e");
      throw Exception("저장 실패");
    }
  }

  // [불러오기] 명함첩 목록
  Stream<List<Map<String, dynamic>>> getConnectionsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('contacts')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ==================================================================
  // 3. 범프 매칭 시스템 (Bump Matching - 위치 기반)
  // ==================================================================

  // [매칭 요청 생성] 위치 정보 포함
  Future<String> createBumpRequest(String uid, Map<String, dynamic> myCardData) async {
    try {
      // 1. 현재 위치 가져오기 (이 함수가 클래스 내부에 정의되어 있어야 함)
      Position position = await _determinePosition();

      DocumentReference ref = await _db.collection('bump_requests').add({
        'requesterUid': uid,
        'cardData': myCardData,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'searching',
        'matchedWith': null,
        // [핵심] 위치 정보 저장
        'location': GeoPoint(position.latitude, position.longitude), 
      });
      return ref.id;
    } catch (e) {
      print("❌ 매칭 요청 실패: $e");
      rethrow;
    }
  }

  Future<void> cancelBumpRequest(String requestId) async {
    try {
      await _db.collection('bump_requests').doc(requestId).delete();
      print("🧹 매칭 요청 삭제 완료 ($requestId)");
    } catch (e) {
      print("❌ 삭제 실패: $e");
    }
  }

  Stream<DocumentSnapshot> getBumpRequestStream(String requestId) {
    return _db.collection('bump_requests').doc(requestId).snapshots();
  }

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

  // ==================================================================
  // 4. 유틸리티 함수 (클래스 내부)
  // ==================================================================
  
  // [누락되었던 함수] 현재 위치 권한 확인 및 좌표 반환
  // 이 함수가 클래스(DatabaseService) 안에 있어야 합니다.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 위치 서비스 켜져있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스(GPS)가 꺼져 있습니다.');
    }

    // 2. 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되었습니다.');
    }

    // 3. 현재 위치 반환
    return await Geolocator.getCurrentPosition();
  }
  
  // ==================================================================
  // 5. 소셜 인터랙션 (스티커 방명록)
  // ==================================================================

  Future<void> sendSticker({
    required String targetUid,
    required String myUid, 
    required String myName,
    required String stickerType,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(targetUid)
          .collection('guestbook')
          .add({
        'fromUid': myUid,
        'fromName': myName,
        'stickerType': stickerType,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("✅ 스티커 전송 완료");
    } catch (e) {
      print("❌ 스티커 전송 실패: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getGuestbookStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('guestbook')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

} // 클래스 끝