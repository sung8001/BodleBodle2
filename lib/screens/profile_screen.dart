import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/cloudinary_image_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isMyProfile;

  const ProfileScreen({
    super.key,
    this.isMyProfile = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _lineColor = Color(0xFFE0E0E0);
  static const Color _placeholderColor = Color(0xFFD9D9D9);

  Widget _buildDefaultAvatar({double size = 82}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE8E8E8),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: size * 0.62,
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl) {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD2D2D2),
          width: 1.2,
        ),
      ),
      child: ClipOval(
        child: imageUrl == null || imageUrl.trim().isEmpty
            ? _buildDefaultAvatar()
            : Image.network(
                imageUrl,
                width: 82,
                height: 82,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              ),
      ),
    );
  }

  int _readCount(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value is num ? value.toInt() : 0;
  }

  Widget _buildStat(int count, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    String? subtitle,
    bool showViewAll = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF777777),
                  ),
                ),
              ),
              if (showViewAll)
                const Text(
                  '전체 보기→',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
            ],
          ),
        ] else if (showViewAll) ...[
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '전체 보기→',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArchivePlaceholders({bool showTitles = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            // 세 카드 모두 좌우 여백을 동일하게 적용해 실제 이미지 폭과 높이를 맞춥니다.
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 0.72,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _placeholderColor,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: const Color(0xFFD0D0D0),
                        width: 0.7,
                      ),
                    ),
                  ),
                ),
                if (showTitles) ...[
                  const SizedBox(height: 8),
                  const SizedBox(
                    height: 22,
                    child: Center(
                      child: Text(
                        '제목',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> data) {
    final nickname = data['nickname'] as String? ?? '닉네임';
    final userId = data['userId'] as String? ?? '';
    final bio = data['bio'] as String? ?? '';
    final profileImageUrl = data['profileImageUrl'] as String?;

    // 아직 감상 기록/팔로우 데이터 연결 전이므로 저장된 숫자가 없으면 0으로 표시합니다.
    final movieCount = _readCount(data, 'movieCount');
    final followerCount = _readCount(data, 'followerCount');
    final followingCount = _readCount(data, 'followingCount');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(profileImageUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$userId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isMyProfile) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 1),
                    minimumSize: const Size(68, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'edit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // 기존 자기소개 데이터와 편집 기능은 유지하고, 프로필 정보 바로 아래에 표시합니다.
          Padding(
            padding: const EdgeInsets.only(left: 104, top: 9, right: 4),
            child: Text(
              bio.isEmpty ? '자기소개를 작성해 보세요.' : bio,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF666666),
              ),
            ),
          ),

          const SizedBox(height: 28),
          Row(
            children: [
              _buildStat(movieCount, 'Movies'),
              _buildStat(followerCount, 'Follower'),
              _buildStat(followingCount, 'Following'),
            ],
          ),

          const SizedBox(height: 26),
          const Divider(height: 1, thickness: 1, color: _lineColor),
          const SizedBox(height: 20),

          _buildSectionHeading(
            title: 'MY MOVIE ARCHIVE',
            subtitle: '내가 기록한 영화',
          ),
          const SizedBox(height: 16),
          _buildArchivePlaceholders(),

          const SizedBox(height: 28),
          const Divider(height: 1, thickness: 1, color: _lineColor),
          const SizedBox(height: 20),

          _buildSectionHeading(
            title: 'MY TICKET',
            showViewAll: true,
          ),
          const SizedBox(height: 16),
          _buildArchivePlaceholders(showTitles: false),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(
        child: Text('로그인이 필요합니다.'),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('프로필을 불러올 수 없습니다.'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final data = snapshot.data?.data();
        if (data == null) {
          return const Center(
            child: Text('프로필 정보가 없습니다.'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SizedBox(
                    width: constraints.maxWidth > 760
                        ? 760
                        : constraints.maxWidth,
                    child: _buildProfileContent(data),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _profilePreviewBytes;
  XFile? _profileImageFile;
  String? _uploadedProfileUrl;
  String? _savedProfileUrl;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();

      if (data == null) {
        throw Exception('회원정보가 존재하지 않습니다.');
      }

      if (!mounted) return;

      _bioController.text = data['bio'] as String? ?? '';
      _nicknameController.text = data['nickname'] as String? ?? '';
      _savedProfileUrl = data['profileImageUrl'] as String?;
    } catch (e) {
      _loadFailed = true;
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필 정보를 불러오지 못했습니다.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickProfileImage() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      const maxBytes = 5 * 1024 * 1024;
      if (await image.length() > maxBytes) {
        throw Exception('5MB 이하의 이미지를 선택해주세요.');
      }

      final imageBytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _profilePreviewBytes = imageBytes;
        _profileImageFile = image;
        _uploadedProfileUrl = null;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 선택 실패: $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading || _isSaving || _loadFailed || _isPickingImage) {
      return;
    }

    final nickname = _nicknameController.text.trim().toLowerCase();
    final bio = _bioController.text.trim();

    if (!RegExp(r'^[a-z0-9가-힣_]{2,20}$').hasMatch(nickname)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임 형식을 확인해주세요.'),
        ),
      );
      return;
    }

    if (bio.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자기소개는 50자 이하로 입력해주세요.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? profileUrl = _uploadedProfileUrl;

      if (_profileImageFile != null && profileUrl == null) {
        profileUrl = await CloudinaryImageService.uploadImage(
          _profileImageFile!,
        );
        _uploadedProfileUrl = profileUrl;
      }

      await AuthService().saveProfile(
        nickname: nickname,
        bio: bio,
        profileImageUrl: profileUrl,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '저장 실패: ${AuthService.readableError(e)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildAvatarPreview() {
    Widget image;

    if (_profilePreviewBytes != null) {
      image = Image.memory(
        _profilePreviewBytes!,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
      );
    } else if (_savedProfileUrl != null && _savedProfileUrl!.isNotEmpty) {
      image = Image.network(
        _savedProfileUrl!,
        width: 104,
        height: 104,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _defaultAvatarPreview();
        },
      );
    } else {
      image = _defaultAvatarPreview();
    }

    return Center(
      child: GestureDetector(
        onTap: _isPickingImage ? null : _pickProfileImage,
        child: Container(
          width: 110,
          height: 110,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFD2D2D2),
              width: 1.2,
            ),
          ),
          child: Stack(
          children: [
            ClipOval(child: image),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatarPreview() {
    return Container(
      width: 104,
      height: 104,
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 65,
      ),
    );
  }

  @override
  void dispose() {
    _bioController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('프로필 수정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatarPreview(),
                  const SizedBox(height: 30),

                  const Text(
                    '닉네임',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nicknameController,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '변경할 닉네임',
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text(
                    '자기소개 (최대 50자)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLength: 50,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '나를 소개하는 문장을 작성해 보세요.',
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isSaving || _loadFailed || _isPickingImage)
                          ? null
                          : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        _isSaving ? '저장 중...' : '저장',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
