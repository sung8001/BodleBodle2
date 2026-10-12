
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryImageService { 
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'z6ijbnix',
  );

  static const String uploadPreset =
      String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'povie_dev_unsigned',
  );

  // 이미지 한 장을 Cloudinary에 업로드
  static Future<String> uploadImage(XFile image) async {
    if (cloudName.isEmpty) {
      throw Exception('Cloudinary Cloud name이 설정되지 않았습니다.');
    }

    // 파일 확장자 검사
    final extension = image.name.split('.').last.toLowerCase();

    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      throw Exception('지원하지 않는 이미지 형식입니다.');
    }

    // 파일 크기 검사 (최대 5MB)
    final fileSize = await image.length();

    if (fileSize > 5 * 1024 * 1024) {
      throw Exception('이미지는 5MB 이하만 업로드할 수 있습니다.');
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    // Cloudinary 업로드 요청
    final request = http.MultipartRequest('POST', url);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await image.readAsBytes(),
        filename: image.name,
      ),
    );

    final streamedResponse = await request.send();
    final response =
        await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        '이미지 업로드 실패 (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    final imageUrl = data['secure_url'] as String?;

    if (imageUrl == null || imageUrl.isEmpty) {
      throw Exception('이미지 주소를 받아오지 못했습니다.');
    }

    return imageUrl;
  }
}
