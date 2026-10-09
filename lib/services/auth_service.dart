
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> signUp({
    required String email,
    required String userId,
    required String nickname,
    required String password,
    required String confirmPassword,
  }) async {
    final cleanEmail = email.trim();
    final cleanId = userId.trim().toLowerCase();
    final cleanNickname = nickname.trim().toLowerCase();

    // 입력값 검사
    if (password != confirmPassword) {
      throw Exception('비밀번호가 일치하지 않습니다.');
    }

    if (password.length < 6) {
      throw Exception('비밀번호는 6자 이상이어야 합니다.');
    }

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(cleanId)) {
      throw Exception('아이디 형식을 확인해주세요.');
    }

    if (!RegExp(r'^[a-z0-9가-힣_]{2,20}$')
        .hasMatch(cleanNickname)) {
      throw Exception('닉네임 형식을 확인해주세요.');
    }

    // 아이디 및 닉네임 중복 사전 확인
    final idDoc =
        await _db.collection('user_ids').doc(cleanId).get();

    if (idDoc.exists) {
      throw Exception('이미 사용 중인 아이디입니다.');
    }

    final nicknameDoc = await _db
        .collection('nickname_keys')
        .doc(cleanNickname)
        .get();

    if (nicknameDoc.exists) {
      throw Exception('이미 사용 중인 닉네임입니다.');
    }

    // Firebase Authentication 계정 생성
    // 이전에 계정 생성 후 DB 저장만 실패했다면 재시도 가능
    User user;
    final current = _auth.currentUser;

    if (current != null &&
        !current.isAnonymous &&
        current.email?.toLowerCase() ==
            cleanEmail.toLowerCase()) {
      user = current;
    } else {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      user = credential.user!;
    }

    final uid = user.uid;

    // 관련 DB 문서를 한 번에 저장
    final batch = _db.batch();

    batch.set(_db.collection('users').doc(uid), {
      'userId': cleanId,
      'nickname': cleanNickname,
      'profileImageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_db.collection('user_private').doc(uid), {
      'email': user.email,
      'phoneNumber': null,
    });

    batch.set(_db.collection('user_ids').doc(cleanId), {
      'uid': uid,
    });

    batch.set(
      _db.collection('nickname_keys').doc(cleanNickname),
      {'uid': uid},
    );

    await batch.commit();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }
}
