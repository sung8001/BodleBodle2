
import 'dart:convert';

import 'package:http/http.dart' as http;

class TmdbService {
  // tmdb.local.json에서 전달받은 API 키
  static const String _apiKey =
      String.fromEnvironment('TMDB_API_KEY');

  // 영화 제목으로 검색
  static Future<List<Map<String, dynamic>>> searchMovies({
    required String query,
  }) async {
    final keyword = query.trim();

    if (keyword.isEmpty) {
      return [];
    }

    if (_apiKey.isEmpty) {
      throw Exception('TMDB API 키가 설정되지 않았습니다.');
    }

    final url = Uri.https(
      'api.themoviedb.org',
      '/3/search/movie',
      {
        'api_key': _apiKey,
        'query': keyword,
        'language': 'ko-KR',
        'include_adult': 'false',
      },
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        '영화 검색에 실패했습니다. (${response.statusCode})',
      );
    }

    final data = jsonDecode(
      utf8.decode(response.bodyBytes),
    ) as Map<String, dynamic>;

    final results = data['results'] as List<dynamic>;

    return results
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
