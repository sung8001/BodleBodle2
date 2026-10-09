import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'main_wrapper_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isMyProfile;
  const ProfileScreen({super.key, this.isMyProfile = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  Widget _buildMyProfileInfo() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Text('로그인이 필요합니다.');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('프로필을 불러올 수 없습니다.');
        }

        if (!snapshot.hasData) {
          return const Text('프로필을 불러오는 중...');
        }

        final data = snapshot.data!.data();

        if (data == null) {
          return const Text('프로필 정보가 없습니다.');
        }

        // Firestore에서 사용자 정보 가져오기
        final nickname =
            data['nickname'] as String? ?? '닉네임 없음';

        final userId =
            data['userId'] as String? ?? '';

        final titleBadge =
            data['titleBadge'] as String? ?? '칭호 없음';

        final bio =
            data['bio'] as String? ?? '';

        // 불러온 정보를 화면에 표시
        return Column(
          children: [
            Text(
              nickname,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              '@$userId',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                titleBadge,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 12,
              ),
              child: Text(
                bio.isEmpty
                    ? '자기소개를 작성해 보세요.'
                    : bio,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                color: const Color(0xFF2C2C2C),
                child: Image.asset(
                  'assets/images/onboarding1_1.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey[800]),
                ),
              ),
              Positioned(
                bottom: -40,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    color: const Color(0xFFE5E5E5),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          _buildMyProfileInfo(),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '팔로워 128',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(width: 20),
              Text(
                '팔로잉 95',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.isMyProfile)
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
              ),
              child: const Text(
                '프로필 수정',
                style: TextStyle(color: Colors.black),
              ),
            ),
            
          if (widget.isMyProfile)
            TextButton(
              onPressed: () async {
                try {
                  // Firebase 로그아웃
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) return;

                  // 이전 화면 기록을 지우고 로그인 화면으로 이동
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          const MainWrapperScreen(startAtLogin: true),
                    ),
                    (route) => false,
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('로그아웃에 실패했습니다.'),
                    ),
                  );
                }
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.black),
              ),
            ),

          const Divider(height: 32, thickness: 1),
          const Text(
            '내 감상 기록 목록',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 20),
        ],
      ),
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

  // 사진은 아직 서버에 업로드하지 않고, 이 화면에서만 미리 보여줍니다.
  Uint8List? _profilePreviewBytes;
  Uint8List? _backgroundPreviewBytes;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _loadFailed = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _loadBio();
  }

  Future<void> _loadBio() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('로그인이 필요합니다.');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null) throw Exception('회원정보가 존재하지 않습니다.');
      if (!mounted) return;

      _bioController.text = data['bio'] as String? ?? '';
      _nicknameController.text = data['nickname'] as String? ?? '';
    } catch (e) {
      _loadFailed = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필 정보를 불러오지 못했습니다.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage({required bool isBackground}) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      // Flutter Web에서도 readAsBytes()를 사용하면 동일하게 미리보기 가능
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isBackground ? 1920 : 800,
        imageQuality: 85,
      );
      if (image == null) return; // 사용자가 사진 선택을 취소한 경우

      // 너무 큰 파일로 인한 메모리 사용량 증가를 방지
      const maxBytes = 5 * 1024 * 1024;
      if (await image.length() > maxBytes) {
        throw Exception('5MB 이하의 이미지를 선택해주세요.');
      }

      final imageBytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        if (isBackground) {
          _backgroundPreviewBytes = imageBytes;
        } else {
          _profilePreviewBytes = imageBytes;
        }
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 선택 실패: $message')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // 기존 '닉네임 + 자기소개' 저장은 그대로 유지합니다.
  // 사진이 선택되었다면 저장이 안 되는 점을 사용자에게 먼저 알립니다.
  Future<void> _saveProfile() async {
    if (_isLoading || _isSaving || _loadFailed || _isPickingImage) return;

    final hasUnsavedImage =
        _profilePreviewBytes != null || _backgroundPreviewBytes != null;

    if (hasUnsavedImage) {
      final saveTextOnly = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('사진은 아직 미리보기만 가능해요'),
          content: const Text(
            '이번 단계에서는 선택한 사진이 서버에 저장되지 않습니다. '
            '닉네임과 자기소개만 저장하고 나갈까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('계속 수정'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('글만 저장'),
            ),
          ],
        ),
      );
      if (!mounted || saveTextOnly != true) return;
    }

    setState(() => _isSaving = true);
    try {
      await AuthService().saveProfile(
        nickname: _nicknameController.text,
        bio: _bioController.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.readableError(e))),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 수정 화면 미리보기: 배경사진과 원형 프로필 사진만 표시합니다.
  // 닉네임, 아이디, 칭호, 자기소개, 팔로우 정보는 여기서 표시하지 않습니다.
  Widget _buildProfilePreview() {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 기존 프로필 화면과 동일한 배경 높이
            SizedBox(
              width: double.infinity,
              height: 140,
              child: _backgroundPreviewBytes == null
                  ? Image.asset(
                      'assets/images/onboarding1_1.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey.shade800),
                    )
                  : Image.memory(
                      _backgroundPreviewBytes!,
                      fit: BoxFit.cover,
                    ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: FilledButton.tonalIcon(
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(isBackground: true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('배경 변경'),
              ),
            ),
            // 배경과 겹치는 기존 크기 84px의 원형 프로필 사진
            Positioned(
              bottom: -40,
              child: GestureDetector(
                onTap: _isPickingImage
                    ? null
                    : () => _pickImage(isBackground: false),
                child: Container(
                  width: 84,
                  height: 84,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_profilePreviewBytes != null)
                          Image.memory(
                            _profilePreviewBytes!,
                            fit: BoxFit.cover,
                          )
                        else
                          const ColoredBox(
                            color: Color(0xFFE5E5E5),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          left: 0,
                          child: ColoredBox(
                            color: Color(0x88000000),
                            child: Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.photo_camera_outlined,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 원형 사진이 배경 밑으로 40px 튀어나오므로 최소 50px 간격 유지
        const SizedBox(height: 50),
      ],
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
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfilePreview(),
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      '사진은 이 화면에서만 미리 볼 수 있어요. '
                      '서버 저장은 다음 단계에서 연결합니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '닉네임',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                        const SizedBox(height: 24),
                        const Text(
                          '자기소개 (최대 50자 제한)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bioController,
                          maxLength: 50,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (_isLoading ||
                                    _isSaving ||
                                    _loadFailed ||
                                    _isPickingImage)
                                ? null
                                : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                            child: Text(
                              _isSaving ? '저장 중...' : '저장',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
