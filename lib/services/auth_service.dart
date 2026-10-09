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

    if (password != confirmPassword) {
      throw Exception('비밀번호가 일치하지 않습니다.');
    }
    if (password.length < 6) {
      throw Exception('비밀번호는 6자 이상이어야 합니다.');
    }
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(cleanId)) {
      throw Exception('아이디는 영문 소문자/숫자/밑줄 3~20자만 가능합니다.');
    }
    if (!RegExp(r'^[a-z0-9가-힣_]{2,20}$').hasMatch(cleanNickname)) {
      throw Exception('닉네임은 한글/영문/숫자/밑줄 2~20자만 가능합니다.');
    }

    // 가입 전 중복 여부를 검사하되, 동시 가입의 최종 보호는 Firestore 규칙이 담당
    final idDoc = await _db.collection('user_ids').doc(cleanId).get();
    if (idDoc.exists) throw Exception('이미 사용 중인 아이디입니다.');

    final nicknameDoc = await _db.collection('nickname_keys')
        .doc(cleanNickname).get();
    if (nicknameDoc.exists) throw Exception('이미 사용 중인 닉네임입니다.');

    // 인증 계정 생성. 이전에 프로필 저장만 실패했다면 본인 비밀번호 재인증 후 재시도
    late User user;
    final current = _auth.currentUser;
    if (current != null && !current.isAnonymous &&
        current.email?.toLowerCase() == cleanEmail.toLowerCase()) {
      await current.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: cleanEmail, password: password),
      );
      user = current;
    } else {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      user = credential.user!;
    }

    final uid = user.uid;
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
    batch.set(_db.collection('user_ids').doc(cleanId), {'uid': uid});
    batch.set(_db.collection('nickname_keys').doc(cleanNickname), {'uid': uid});
    await batch.commit();

    // 회원가입 완료 후 사용자가 직접 이메일/비밀번호로 로그인하게 함
    await _auth.signOut();
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

  static String readableError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return '이미 가입된 이메일입니다. 로그인해 주세요.';
        case 'invalid-email':
          return '이메일 형식을 확인해 주세요.';
        case 'weak-password':
          return '비밀번호가 너무 약합니다. 더 안전한 비밀번호를 설정해 주세요.';
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-credential':
          return '이메일 또는 비밀번호를 확인해 주세요.';
        case 'too-many-requests':
          return '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요.';
        case 'operation-not-allowed':
          return 'Firebase Console에서 이메일/비밀번호 로그인을 활성화해 주세요.';
      }
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'DB 접근이 차단됐습니다. Firestore 보안 규칙을 확인해 주세요.';
    }
    if (error is FirebaseException && error.code == 'unavailable') {
      return '네트워크 연결 후 다시 시도해 주세요.';
    }
    if (error is Exception && error.toString().startsWith('Exception: ')) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';
  }
}
