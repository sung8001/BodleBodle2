//사용자 데이터값
class UserModel {
  final String email;
  final String id;
  final String nickname;

  UserModel({required this.email, required this.id, required this.nickname});

  // 나중에 백엔드(서버)나 데이터베이스와 JSON 형식으로 주고받을 때를 대비한 변환 함수들
  Map<String, dynamic> toJson() {
    return {'email': email, 'id': id, 'nickname': nickname};
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] ?? '',
      id: json['id'] ?? '',
      nickname: json['nickname'] ?? '',
    );
  }
}
